 

pragma solidity 0.5.13;
interface Out{function check(address w)external view returns(bool);}
contract REGISTER{
    address private own;address private uni;uint256 private cnt=4;
    modifier onlyOwn{require(own==msg.sender);_;} 
    modifier infra{require(Out(uni).check(msg.sender));_;}
	mapping(uint256=>address)private ac;mapping(address=>uint256)private id;
	mapping(address=>address)private rref;mapping(address=>uint256)private rdate;
    address private rvs=0xd8E399398839201C464cda7109b27302CFF0CEaE;
    address private fts=0xc0ae03412B19B4303cc67603B54d1309b19Df158;
    address private sts=0xd1d5bd873AA0A064C3Bd78266a9C7149510fAC41;
	mapping(address=>address[])public fref;mapping(address=>address[])public sref;
	function rff(address a,address b)private returns(bool){
		rdate[a]=now;rref[a]=b;fref[b].push(a);sref[rref[b]].push(a);return true;}
    function _register(address a,address b)private returns(bool){
		require(id[b]!=0);if(id[a]==0){ac[cnt+now]=a;id[a]=cnt+now;cnt=cnt+1;require(rff(a,b));}return true;}
    function register(address a,address b)external infra returns(bool){require(_register(a,b));return true;}
    function segister(address b)external infra returns(bool){require(_register(msg.sender,b));return true;}
    function total()external view returns(uint256){return cnt-1;}
    function acc(uint256 a)external view returns(address){return ac[a];}
    function idd(address a)external view returns(uint256){return id[a];}
    function ref(address a)external view returns(address){return rref[a];}
    function sef(address a)external view returns(address){return rref[rref[a]];}
    function pro(address a)external view returns(uint256,uint256,uint256){return(fref[a].length,sref[a].length,rdate[a]);}
    function setuni(address a)external onlyOwn returns(bool){uni=a;return true;}
	function()external{revert();}
	constructor()public{own=msg.sender;
	   id[rvs]=1000000000;ac[1000000000]=rvs;rref[rvs]=rvs;
	   id[fts]=1100000000;ac[1100000000]=fts;rref[fts]=fts;
	   id[sts]=1200000000;ac[1200000000]=sts;rref[sts]=sts;}}