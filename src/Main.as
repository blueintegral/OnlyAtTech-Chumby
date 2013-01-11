/**
 * Main class with everything.
 * This is based on the FMyLife widget by Samuel Lai.
 * It was modified by Hunter Scott, but most of the code was written by Sameul Lai. Thanks Sam! 
 * @author Samuel Lai and Hunter Scott
 */
import com.chumby.util.MCUtil;
import com.chumby.util.xml.XmlUtil;
import com.chumby.util.Delegate;
 
class Main extends MovieClip
{
	//{ constants
	private var MC_WIDTH:Number = 320;
	private var MC_HEIGHT:Number = 240;
	
	private var HEADER_HEIGHT:Number = 30;
	private var ITEMTEXT_HEIGHT:Number = 170;
	
	private var HEADINGTEXT_DEPTH:Number = 0;
	private var ITEMTITLETEXT_DEPTH:Number = 1;
	private var ITEMTEXT_DEPTH:Number = 2;
	private var NEXTBUTTON_DEPTH:Number = 10;
	private var PAUSEBUTTON_DEPTH:Number = 11;
	private var PREVBUTTON_DEPTH:Number = 12;
	
	private var ROTATE_INTERVAL:Number = 1000 * 15; //15 secs
	//}
	
	//{ instance variables
	private var _itemTitleText:TextField;
	private var _itemText:TextField;
	
	private var _nextButton:BasicButton;
	private var _pauseButton:BasicButton;
	private var _prevButton:BasicButton;
	
	private var _xml:XML;
	
	private var _entries:Array;
	private var _curEntryIndex:Number;
	
	private var _isPaused:Boolean;
	private var _skipAutoRotate:Boolean; //when just after next/prev has been pressed
	//}
	
	//{ entry point method
	public static function main(swfRoot:MovieClip):Void 
	{
		// entry point
		var mainMC:MovieClip = MCUtil.CreateWithClass(Main, _root, "main", 1, {});
	}
	//}
	
	public function Main() 
	{
		_isPaused = false;
		
		paintUI();
		generateUI();
		
		startDownloadFeed();
	}
	
	private function paintUI():Void
	{
		this.clear();
		
		//paint background
		this.moveTo(0, 0);
		this.beginGradientFill("linear", [0xFFFF82, 0xFFFFFF], [100, 100], [0, 0x99], {
			matrixType:"box", x:0, y:0, w:MC_WIDTH, h:MC_HEIGHT, r:Math.PI/2
		});
		this.lineTo(MC_WIDTH, 0);
		this.lineTo(MC_WIDTH, MC_HEIGHT);
		this.lineTo(0, MC_HEIGHT);
		this.endFill();
		
		//paint text box
		this.moveTo(10, HEADER_HEIGHT);
		this.lineStyle(1, 0x999999, 100);
		this.beginFill(0xFFFFFF, 100);
		this.lineTo(MC_WIDTH - 10, HEADER_HEIGHT);
		this.lineTo(MC_WIDTH - 10, MC_HEIGHT - 10);
		this.lineTo(10, MC_HEIGHT - 10);
		this.endFill();
		
		//paint item title box
		this.moveTo(10 + 1 /* avoid line */, HEADER_HEIGHT + 1 /* avoid lines */);
		this.lineStyle(0, 0x000000, 0);
		this.beginFill(0xCCCCCC, 100);
		this.lineTo(MC_WIDTH - 10, HEADER_HEIGHT + 1 /* avoid lines */);
		this.lineTo(MC_WIDTH - 10, HEADER_HEIGHT + 27);
		this.lineTo(10 + 1 /* avoid line */, HEADER_HEIGHT + 28);
		this.endFill();
	}
	
	private function generateUI():Void
	{
		var tf:TextFormat = null;
		
		var headingText:TextField = this.createTextField("headingText", HEADINGTEXT_DEPTH, 10, 3, MC_WIDTH - 10 /* x */, HEADER_HEIGHT - 3 /* y */);
		tf = new TextFormat();
		tf.font = "Arial";
		tf.size = 16;
		tf.bold = true;
		headingText.setNewTextFormat(tf);
		headingText.text = "Only at Tech";
		
		_prevButton = MCUtil.CreateWithClass(BasicButton, this, "prevButton", PREVBUTTON_DEPTH, { _x:125, _y:3 }, ["Prev"]);
		_prevButton.onPress = Delegate.create(this, prevButtonClicked);
		
		_pauseButton = MCUtil.CreateWithClass(BasicButton, this, "pauseButton", PAUSEBUTTON_DEPTH, { _x:185, _y:3 }, ["Pause"]);
		_pauseButton.onPress = Delegate.create(this, pauseButtonClicked);
		
		_nextButton = MCUtil.CreateWithClass(BasicButton, this, "nextButton", NEXTBUTTON_DEPTH, { _x:254, _y:3 }, ["Next"]);
		_nextButton.onPress = Delegate.create(this, nextButtonClicked);
		
		_itemTitleText = this.createTextField("itemTitleText", ITEMTITLETEXT_DEPTH, 15, HEADER_HEIGHT + 3, MC_WIDTH - 30 /* x */, 24);
		tf = new TextFormat();
		tf.font = "Arial";
		tf.size = 14;
		tf.bold = true;
		_itemTitleText.setNewTextFormat(tf);
		
		_itemText = this.createTextField("itemText", ITEMTEXT_DEPTH, 15, HEADER_HEIGHT + 3 + 24 + 3, MC_WIDTH - 30 /* x */, ITEMTEXT_HEIGHT);
		tf = new TextFormat();
		tf.font = "Arial";
		tf.size = 12;
		tf.bold = false;
		_itemText.setNewTextFormat(tf);
		_itemText.multiline = true;
		_itemText.wordWrap = true;
	}
	
	private function setStatusText(status:String):Void
	{
		_itemTitleText.text = status;
		_itemText.text = "";
	}
	
	private function startDownloadFeed():Void
	{
		setStatusText("Loading...");
		
		_xml = new XML();
		_xml.ignoreWhite = true;
		_xml.onLoad = Delegate.create(this, feedReceived);
		
		var url:String = "http://feeds.feedburner.com/OnlyAtTech";

		_xml.load(url);
	}
	
	private function feedReceived(success:Boolean):Void
	{
		if (success == false)  
		{
			setStatusText("Could not download feed.");
			return;
		}
		
		setStatusText("Parsing...");
		
		var curNode:XMLNode;
		
		//clear existing entries
		_entries = [];
		_curEntryIndex = -1;
		
		//determine if atom or rss
		//can be either, because it depends on Feedburner's stupid SmartFeed 'feature' which auto-detects.
		//on Vista/7, it gives IE8 RSS, with no option to override - WTF.
		var isAtom:Boolean = true;
		trace(_xml.firstChild.nodeName);
		if (_xml.firstChild.nodeName == "rss")
			isAtom = false;
			
		//get all entries
		var entryNodes:Array;
		if (!isAtom)
			entryNodes = XmlUtil.childrenOfType(_xml.firstChild.firstChild, "item");
		else
			entryNodes = XmlUtil.childrenOfType(_xml.firstChild, "entry");
		
		for (var i:Number = 0; i < entryNodes.length; i++)
		{
			var entryNode:XMLNode = entryNodes[i];
			var curEntry:Object = { };
			
			//get title
			curNode = XmlUtil.firstChildOfType(entryNode, "title");
			curEntry["title"] = curNode.firstChild.nodeValue;
			
			//get contents
			if (!isAtom)
				curNode = XmlUtil.firstChildOfType(entryNode, "description");
			else
				curNode = XmlUtil.firstChildOfType(entryNode, "content");
			var content:String = curNode.firstChild.nodeValue;
			
			//strip off the feedburner spy image at the end
			if (content.indexOf("<") >= 0)
				content = content.substring(0, content.indexOf("<"));
			
			curEntry["content"] = content;
			
		_entries.push(curEntry);
		
		}
		
		
		//clean up
		_xml = null;
		
		//update UI
		changeToIndex(0);
		
		//start stories rotating
		setInterval(this, "changeTimerTicked", ROTATE_INTERVAL);
	}
	
	private function changeTimerTicked():Void
	{
		//set to true when next/prev button has just been pressed - otherwise timing may mean it advances twice
		if (_skipAutoRotate)
		{
			_skipAutoRotate = false;
			return;
		}
		
		if (!_isPaused)
			changeToIndex();
	}
	
	private function changeToIndex(index:Number):Void
	{
		//check if any entries exist
		if (_entries.length == 0)
		{
			setStatusText("No entries available.");
			return;
		}
		
		//auto increment
		if (index == undefined)
		{
			index = _curEntryIndex + 1;
			if (index >= _entries.length)
				index = index % (_entries.length - 1);
		}
		
		//out of range
		if (index >= _entries.length)
			index = index % (_entries.length - 1);
			
		if (index < 0)
			index = _entries.length - (Math.abs(index) % (_entries.length - 1));
		
		_itemTitleText.text = _entries[index]["title"];
		var content:String = _entries[index]["content"];
		
		//size item text so it fills space
		var tf:TextFormat = new TextFormat();
		tf.size = 20; //start at a large number and work down
		
		while (tf.getTextExtent(content, _itemText._width)["textFieldHeight"] > (ITEMTEXT_HEIGHT - 40 /* leeway */)) //was 10, changed to 40 to fix bug where
		{                                                                                                            // last part of sentence got cut off.
			tf.size -= 1;
		}
		
		_itemText.text = content;
		_itemText.setTextFormat(tf);
		
		_curEntryIndex = index;
	}
	
	private function nextButtonClicked():Void
	{
		_skipAutoRotate = true;
		changeToIndex(++_curEntryIndex);
	}
	
	private function prevButtonClicked():Void
	{
		_skipAutoRotate = true;
		changeToIndex(--_curEntryIndex);
	}
	
	private function pauseButtonClicked():Void
	{
		if (_isPaused)
		{
			_isPaused = false;
			_pauseButton.setLabel("Pause");
		}
		else
		{
			_isPaused = true;
			_pauseButton.setLabel("Play");
		}
	}
}