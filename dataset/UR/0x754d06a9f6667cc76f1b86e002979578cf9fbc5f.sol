 

pragma solidity ^ 0.4.25;
 
contract owned {

    address public owner;

    constructor() public {
    owner = msg.sender;
    }
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }   
}
contract lepaitoken is owned{
    uint public systemprice;
    struct putusers{
	    	address puser; 
	    	uint addtime; 
	    	uint addmoney;  
	    	string useraddr;  
    }
    struct auctionlist{
        address adduser; 
        uint opentime; 
        uint endtime; 
        uint openprice; 
        uint endprice; 
        uint onceprice; 
        uint currentprice; 
        string goodsname;  
        string goodspic;  
        bool ifend; 
        uint ifsend; 
        uint lastid; 
        mapping(uint => putusers) aucusers; 
        mapping(address => uint) ausers; 
    }
    auctionlist[] public auctionlisting;  
    auctionlist[] public auctionlistend;  
    auctionlist[] public auctionlistts;  
    mapping(address => uint[]) userlist; 
    mapping(address => uint[]) mypostauct; 
     
    btycInterface constant private btyc = btycInterface(0x56F527C3F4a24bB2BeBA449FFd766331DA840FFA);
     
	event auctconfim(address target, uint tokens); 
	event getmoneys(address target, uint tokens); 
	constructor() public {
	    systemprice = 20000 ether;
	}
	 
	function addauction(address addusers,uint opentimes, uint endtimes, uint onceprices, uint openprices, uint endprices, string goodsnames, string goodspics) public returns(uint){
	    uint _now = now;
	    require(opentimes >= _now - 1 hours);
	    require(opentimes < _now + 2 days);
	    require(endtimes > opentimes);
	     
	    require(endtimes < opentimes + 2 days);
	    require(btyc.balanceOf(addusers) >= systemprice);
	    auctionlisting.push(auctionlist(addusers, opentimes, endtimes, openprices, endprices, onceprices, openprices, goodsnames, goodspics, false, 0, 0));
	    uint lastid = auctionlisting.length;
	    mypostauct[addusers].push(lastid);
	    return(lastid);
	}
	 
	function getmypostlastid() public view returns(uint){
	    return(mypostauct[msg.sender].length);
	}
	 
	function getmypost(uint ids) public view returns(uint){
	    return(mypostauct[msg.sender][ids]);
	}
	 
	function balanceOf(address addr) public view returns(uint) {
	    return(btyc.balanceOf(addr));
	}
	 
	function canuse(address addr) public view returns(uint) {
	    return(btyc.getcanuse(addr));
	}
	 
	function ownerof() public view returns(uint) {
	    return(btyc.balanceOf(this));
	}
	 
	function sendleftmoney(uint money, address toaddr) public onlyOwner{
	    btyc.transfer(toaddr, money);
	}
	 
	function inputauction(uint auctids, address pusers, uint addmoneys,string useraddrs) public payable{
	    uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.ifend == false);
	    require(c.ifsend == 0);
	    
	    uint userbalance = canuse(pusers);
	    require(addmoneys > c.currentprice);
	    require(addmoneys <= c.endprice);
	    
	   require(addmoneys > c.ausers[pusers]);
	    uint money = addmoneys - c.ausers[pusers];
	    
	    require(userbalance >= money);
	    if(c.endtime < _now) {
	        c.ifend = true;
	    }else{
	        if(addmoneys == c.endprice){
	            c.ifend = true;
	        }
	        btyc.transfer(this, money);
	        c.ausers[pusers] = addmoneys;
	        c.currentprice = addmoneys;
	        c.aucusers[c.lastid++] = putusers(pusers, _now, addmoneys,  useraddrs);
	    
	        userlist[pusers].push(auctids);
	         
	    }
	    
	    
	     
	    
	}
	 
	function getuserlistlength(address uaddr) public view returns(uint len) {
	    len = userlist[uaddr].length;
	}
	 
	function viewauction(uint aid) public view returns(address addusers,uint opentimes, uint endtimes, uint onceprices, uint openprices, uint endprices, uint currentprices, string goodsnames, string goodspics, bool ifends, uint ifsends, uint anum){
		auctionlist storage c = auctionlisting[aid];
		addusers = c.adduser; 
		opentimes = c.opentime; 
		endtimes = c.endtime; 
		onceprices = c.onceprice; 
		openprices = c.openprice; 
		endprices = c.endprice; 
		currentprices = c.currentprice; 
		goodspics = c.goodspic; 
		goodsnames = c.goodsname; 
		ifends = c.ifend; 
		ifsends = c.ifsend; 
		anum = c.lastid; 
		
	}
	 
	function viewauctionlist(uint aid, uint uid) public view returns(address pusers,uint addtimes,uint addmoneys){
	    auctionlist storage c = auctionlisting[aid];
	    putusers storage u = c.aucusers[uid];
	    pusers = u.puser; 
	    addtimes = u.addtime; 
	    addmoneys = u.addmoney; 
	}
	 
	function getactlen() public view returns(uint) {
	    return(auctionlisting.length);
	}
	 
	function getacttslen() public view returns(uint) {
	    return(auctionlistts.length);
	}
	 
	function getactendlen() public view returns(uint) {
	    return(auctionlistend.length);
	}
	 
	function setsendgoods(uint auctids) public {
	    uint _now = now;
	     auctionlist storage c = auctionlisting[auctids];
	     require(c.adduser == msg.sender);
	     require(c.endtime < _now);
	     require(c.ifsend == 0);
	     c.ifsend = 1;
	     c.ifend = true;
	}
	 
	function setgetgoods(uint auctids) public {
	    uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.endtime < _now);
	    require(c.ifend == true);
	    require(c.ifsend == 1);
	    putusers storage lasttuser = c.aucusers[c.lastid];
	    require(lasttuser.puser == msg.sender);
	    c.ifsend = 2;
	    uint getmoney = lasttuser.addmoney*70/100;
	    btyc.mintToken(c.adduser, getmoney);
	    auctionlistend.push(c);
	}
	 
	function getuseraddress(uint auctids) public view returns(string){
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.adduser == msg.sender);
	     
	    return(c.aucusers[c.lastid].useraddr);
	}
	function editusetaddress(uint aid, string setaddr) public returns(bool){
	    auctionlist storage c = auctionlisting[aid];
	    putusers storage data = c.aucusers[c.lastid];
	    require(data.puser == msg.sender);
	    data.useraddr = setaddr;
	    return(true);
	}
	 
	function endauction(uint auctids) public {
	     
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.ifsend == 2);
	    uint len = c.lastid;
	    putusers storage firstuser = c.aucusers[0];
        address suser = msg.sender;
	    
	    require(c.ifend == true);
	    require(len > 1);
	    require(c.ausers[suser] > 0);
	    uint sendmoney = 0;
	    if(len == 2) {
	        require(firstuser.puser == suser);
	        sendmoney = c.currentprice*3/10 + c.ausers[suser];
	    }else{
	        if(firstuser.puser == suser) {
	            sendmoney = c.currentprice*1/10 + c.ausers[suser];
	        }else{
	            uint onemoney = (c.currentprice*2/10)/(len-2);
	            sendmoney = onemoney + c.ausers[suser];
	        }
	    }
	    require(sendmoney > 0);
	    btyc.mintToken(suser, sendmoney);
	    c.ausers[suser] = 0;
	    emit getmoneys(suser, sendmoney);
	    
	}
	 
	function setsystemprice(uint price) public onlyOwner{
	    systemprice = price;
	}
	 
	function setauctionother(uint auctids) public onlyOwner{
	    auctionlist storage c = auctionlisting[auctids];
	    btyc.freezeAccount(c.adduser, true);
	    c.ifend = true;
	    c.ifsend = 3;
	}
	 
	function setauctionsystem(uint auctids, uint setnum) public onlyOwner{
	    auctionlist storage c = auctionlisting[auctids]; 
	    c.ifend = true;
	    c.ifsend = setnum;
	}
	 
	function setauctionotherfree(uint auctids) public onlyOwner{
	    auctionlist storage c = auctionlisting[auctids];
	    btyc.freezeAccount(c.adduser, false);
	    c.ifsend = 2;
	}
	 
	function tsauction(uint auctids) public{
	   auctionlist storage c = auctionlisting[auctids];
	   uint _now = now;
	   require(c.endtime > _now);
	   require(c.endtime + 2 days < _now);
	   require(c.aucusers[c.lastid].puser == msg.sender);
	   if(c.endtime + 2 days < _now && c.ifsend == 0) {
	       c.ifsend = 5;
	       c.ifend = true;
	       auctionlistts.push(c);
	   }
	   if(c.endtime + 9 days < _now && c.ifsend == 1) {
	       c.ifsend = 5;
	       c.ifend = true;
	       auctionlistts.push(c);
	   }
	}
	 
	function endauctionother(uint auctids) public {
	     
	    auctionlist storage c = auctionlisting[auctids];
	    address suser = msg.sender;
	    require(c.ifsend == 3);
	    require(c.ausers[suser] > 0);
	    btyc.mintToken(suser,c.ausers[suser]);
	    c.ausers[suser] = 0;
	    emit getmoneys(suser, c.ausers[suser]);
	}
	
}
 
interface btycInterface {
     
    function balanceOf(address _addr) external view returns (uint256);
    function mintToken(address target, uint256 mintedAmount) external returns (bool);
    function transfer(address to, uint tokens) external returns (bool);
    function freezeAccount(address target, bool freeze) external returns (bool);
    function getcanuse(address tokenOwner) external view returns(uint);
}