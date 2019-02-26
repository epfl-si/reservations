function getUserAccreds (id) {
	var selector = document.getElementById(id);
	var value = selector[selector.selectedIndex].value;
console.log ('value='+value);

	var obj = new XMLHttpRequest();
	var url = 'https://test-reservations.epfl.ch/cgi-bin/res/getUserAccreds?sciper='+value; 
console.log ('url='+url);
	obj.open("GET", url);
	obj.send();
	obj.onreadystatechange=function() 
	{
	  if(obj.readyState==4) 
		document.getElementById('div-unite').innerHTML = obj.responseText; 
	}

}