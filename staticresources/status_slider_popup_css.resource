.spinner {
  -webkit-animation-name: spinnerRotate;
  -webkit-animation-duration: 1s;
  -webkit-animation-iteration-count: infinite;
  -webkit-animation-timing-function: linear;
}

@-webkit-keyframes spinnerRotate {
  from { -webkit-transform:rotate(0deg); }
  to { -webkit-transform:rotate(360deg); }
}  

.popupBackground {
    background-color: rgba(0,0,0,.7);
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    z-index: 998;
    position: absolute;
    cursor:wait;
}  
        
.centered {
    position: absolute;  
    top: 0;  
    bottom: 0;  
    left: 0;  
    right: 0;  
    margin: auto;        
        }  