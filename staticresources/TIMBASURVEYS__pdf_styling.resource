@page{  /* Landscape orientation*/ 
		size:A4;
    	/* Put page numbers in the bottom left corner of each page in the pdf document.*/
	    @bottom-left{
			color: #717171 !important;
		    content: "Page " counter(page) " of " counter(pages);
			border-top: solid 1px #717171 !important;
		}
	    @bottom-right{
			color: #717171 !important;
	    	content: "Surveys Made Easy by Timba Surveys";
	    	border-top: solid 1px #717171 !important;
	    }
		@bottom-center{
	    	border-top: solid 1px #717171 !important;
	    }
	
	margin-top:0;

    }

body { font-family: Arial Unicode MS; }