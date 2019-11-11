# This file is supposed to be sources (preferably in ~/.profile).
# It's compatible with sh/dash.

if [ -z "$_JAVA_OPTIONS" ]; then
	export _JAVA_OPTIONS='
		-Dawt.useSystemAAFontSettings=on
		-Dswing.aatext=true
		-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel
		-Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel
	'
fi

if [ -z "$_JAVA_AWT_WM_NONREPARENTING" ]; then
	export _JAVA_AWT_WM_NONREPARENTING=1
fi
