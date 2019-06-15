
function change_colour( data ) {
	var obj = document.getElementById('colour');
//	alert("DEBUG:change_colour:"+data)
//	obj.innerHTML = data;
	obj.style.background = data;
}

function onICHostReady(version) {
	if ( version != 1.0 ) {
		alert('Invalid API version');
		return;
	}

	gICAPI.currentStyleToApply = "fill:#000000;";
	gICAPI.redrawRequested = false;

	gICAPI.onData = function(data) {
;
		if (data == "") {
			var props = gICAPI.memorizedProps;
			gICAPI.memorizedProps = "x";
			gICAPI.memorizedData = "x";
			change_colour( "<b>none</b>" );
			gICAPI.onProperty(props);
		} else if (data != gICAPI.memorizedData) {
			gICAPI.memorizedData = data;
			change_colour( data );
			if (! gICAPI.redrawRequested) {
				gICAPI.redrawRequested = true;
			}
		} else {
			change_colour( data );
			//alert("DEBUG:onData:ignored!");
		}
	}

	gICAPI.onProperty = function(props) {
		if (props != gICAPI.memorizedProps) {
			gICAPI.memorizedProps = props;
			if (! gICAPI.redrawRequested) {
				gICAPI.redrawRequested = true;
			}
		}
	}
}
