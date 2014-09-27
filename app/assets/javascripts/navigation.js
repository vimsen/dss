 $(document).load(function() {
	
	console.log("load event ...");
		    
});
 

 function highlightNavigation(element){
      
    var pathname = window.location.pathname;
        
    //$('#'+element.id).addClass('active');
    
    //console.log($("ul.nav .active"));
      
    //set latest selected link as active 
    // Will only work if string in href matches with location
    //$('ul.nav a[href="' + url + '"]').parent().addClass('active');

    // Will also work for relative and absolute hrefs
/*    
    $('ul.nav a').filter(function () {
            return this.href == url;
    }).parent().addClass('active').parent().parent().addClass('active');
*/    	

	console.log(element.id);
    
 }

