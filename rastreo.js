/* Seguimiento de lectura de la propuesta: sin cookies, solo eventos de lectura. */
(function(){
try{
 var q=new URLSearchParams(location.search),ls=window.localStorage,ss=window.sessionStorage;
 if(q.has('yo')){q.get('yo')==='0'?ls.removeItem('yo'):ls.setItem('yo','1');}
 var cod=(q.get('r')||'').replace(/[^a-z0-9-]/gi,'').slice(0,24);
 if(cod)ss.setItem('r',cod);else cod=ss.getItem('r')||'';
 if(q.has('r')||q.has('yo')){q.delete('r');q.delete('yo');var qs=q.toString();history.replaceState(history.state,'',location.pathname+(qs?'?'+qs:'')+location.hash);}
 if(ls.getItem('yo')==='1'||navigator.webdriver)return;
 var min=!!(document.currentScript&&document.currentScript.hasAttribute('data-minimo'));
 var v='';if(!min){v=ls.getItem('v');if(!v){v=Math.random().toString(36).slice(2,12);ls.setItem('v',v);}}
}catch(e){return}
var s=Math.random().toString(36).slice(2,12);if(!v)v='s-'+s;var pasos=document.querySelectorAll('.step'),N=pasos.length;
var vistos={},max=0,audios=0,activo=0,t0=Date.now(),iniciado=false,cerrado=false;
function actual(){for(var k=0;k<N;k++)if(pasos[k].classList.contains('on')||!pasos[k].hidden)return k+1;return 1}
function env(tipo,extra){var d={tipo:tipo,v:v,s:s,r:cod,n:N,paso:actual(),max:max,vistos:Object.keys(vistos).length,audios:audios,seg:Math.round(activo/1000),ref:min?'':document.referrer.slice(0,200)};
 for(var k in extra)d[k]=extra[k];var b=JSON.stringify(d);
 if(navigator.sendBeacon&&navigator.sendBeacon('t.php',new Blob([b],{type:'text/plain'})))return;
 try{fetch('t.php',{method:'POST',body:b,keepalive:true,headers:{'Content-Type':'text/plain'}})}catch(e){}}
function marca(){var p=actual();vistos[p]=1;if(p>max)max=p}
function tic(){if(document.visibilityState==='visible'){var a=Date.now();activo+=a-t0;t0=a}else t0=Date.now()}
var avisado=false;
setInterval(function(){tic();marca();if(iniciado&&!avisado&&(activo>=45000||max>=N)){avisado=true;env('fin')}},1000);
try{new MutationObserver(marca).observe(document.body,{subtree:true,attributes:true,attributeFilter:['class','hidden']})}catch(e){}
setTimeout(function(){if(document.visibilityState==='visible'){marca();iniciado=true;env('inicio')}},2500);
document.addEventListener('visibilitychange',function(){tic();if(document.visibilityState==='hidden'&&iniciado)env('fin')});
window.addEventListener('pagehide',function(){tic();if(iniciado&&!cerrado){cerrado=true;env('fin')}});
var op=HTMLMediaElement.prototype.play;HTMLMediaElement.prototype.play=function(){audios++;return op.apply(this,arguments)};
if(window.speechSynthesis){var sp=speechSynthesis.speak.bind(speechSynthesis);speechSynthesis.speak=function(u){audios++;return sp(u)}}
})();
