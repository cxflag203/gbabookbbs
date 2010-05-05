var dialog		= window.parent ;
var oEditor		= dialog.InnerDialogLoaded() ;
var FCK			= oEditor.FCK ;
var FCKLang		= oEditor.FCKLang ;
var FCKConfig	= oEditor.FCKConfig ;
var FCKTools	= oEditor.FCKTools ;

// Function called when a dialog tag is selected.
function OnDialogTabChange( tabCode )
{
	//ShowE('divInfo'		, ( tabCode == 'Info' ) ) ;
}

// Get the selected flash embed (if available).
var oFakeImage = dialog.Selection.GetSelectedElement() ;
var oEmbed ;

if ( oFakeImage )
{
	if ( oFakeImage.tagName == 'IMG' && oFakeImage.getAttribute('_fckflash') )
		oEmbed = FCK.GetRealElement( oFakeImage ) ;
	else
		oFakeImage = null ;
}

window.onload = function()
{
	// Translate the dialog box texts.
	oEditor.FCKLanguageManager.TranslatePage(document) ;

	// Load the selected element information (if any).


	dialog.SetAutoSize( true ) ;

	// Activate the "OK" button.
	dialog.SetOkButton( true ) ;

	SelectField( 'txtUrl' ) ;
}

//#### The OK button was hit.
function Ok()
{
	if ( GetE('txtUrl').value.length == 0 )
	{
		GetE('txtUrl').focus() ;

		alert( oEditor.FCKLang.DlgAlertUrl ) ;

		return false ;
	}

	oEditor.FCKUndo.SaveUndoStep() ;
	if ( !oEmbed )
	{
		oEmbed		= FCK.EditorDocument.createElement( 'EMBED' ) ;
		oFakeImage  = null ;
	}
	UpdateEmbed( oEmbed ) ;

	if ( !oFakeImage )
	{
		oFakeImage	= oEditor.FCKDocumentProcessor_CreateFakeImage( 'FCK__Flash', oEmbed ) ;
		oFakeImage.setAttribute( '_fckflash', 'true', 0 ) ;
		oFakeImage	= FCK.InsertElement( oFakeImage ) ;
	}

	oEditor.FCKEmbedAndObjectProcessor.RefreshView( oFakeImage, oEmbed ) ;

	return true ;
}

function UpdateEmbed( e )
{
	var fileurl = GetE('txtUrl').value;
	var fileext = fileurl.replace(/^.*(\.[^\.\?]*)\??.*$/,'$1').toLowerCase();
	
	if (fileext == '.swf' || fileext == '.mp3'){
		SetAttribute( e, 'type'			, 'application/x-shockwave-flash' ) ;
		SetAttribute( e, 'pluginspage'	, 'http://www.macromedia.com/go/getflashplayer' ) ;
		if (fileext == '.swf'){
			SetAttribute( e, 'src', fileurl ) ;
			SetAttribute( e, "width" , GetE('txtWidth').value ) ;
			SetAttribute( e, "height", GetE('txtHeight').value ) ;
		}
		else{
			fileurl = encodeURIComponent(fileurl);
			fileurl = fileurl.replace(/\./g, '%2E');
			SetAttribute( e, 'src', 'js/player.swf?bg=0xCDDFF3&leftbg=0x357DCE&lefticon=0xF2F2F2&rightbg=0xF06A51&rightbghover=0xAF2910&righticon=0xF2F2F2&righticonhover=0xFFFFFF&text=0x357DCE&slider=0x357DCE&track=0xFFFFFF&border=0xFFFFFF&loader=0xAF2910&soundFile='+ fileurl ) ;
			SetAttribute( e, "width" , '290' ) ;
			SetAttribute( e, "height", '24' ) ;
			SetAttribute( e, "wmode", 'transparent' ) ;
		}
	}else{
		SetAttribute( e, 'src', fileurl ) ;
		SetAttribute( e, "width" , GetE('txtWidth').value ) ;
		SetAttribute( e, "height", GetE('txtHeight').value ) ;
		SetAttribute( e, 'autostart', 'false' ) ;
	}
}