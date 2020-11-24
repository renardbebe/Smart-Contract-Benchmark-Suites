 

pragma solidity ^0.4.25;

contract RISK{

     
    uint16[19][3232] private adjacencies;
    address private admin = msg.sender;
    uint256 private seed = block.timestamp;
    uint256 public roundID;
    mapping(uint256=>RoundData) public Rounds;
    bool public isactive;
    mapping(address=>uint256) private playerlastroundwithdrawn;
    
    
     
    uint16 public beginterritories = 5;  
    uint16 public maxroll= 6;
    uint256 public trucetime=72 hours;
    uint256 public price=30 finney;
    uint256 public maxextensiontruce=50;  
    
    
     
    mapping(bytes32=>address) public ownerXname;  
    mapping(address=>bytes32) public nameXaddress; 
    mapping(bytes32=>uint256) public priceXname;  



     


    function createnation(uint16[] territories,string _name,
    uint256 RGB)
    public
    payable
    {
        RequireHuman();
        require(isactive);
        uint256 _rID = roundID;
        uint16 _teamcnt =Rounds[_rID].teamcnt;
        
        
        require(_teamcnt<255);  
        
        
        RGB=colorfilter(RGB); 
        require(!Rounds[_rID].iscolorregistered[RGB]);  
        
        
        bytes32 name=nameFilter(_name);
        require(ownerXname[name]==msg.sender);  
        require(Rounds[_rID].isnameregistered[name]==false);  


        uint16 _beginterritories =  Rounds[roundID].beginterritories;
        require(msg.value==Rounds[_rID].price);
        require(territories.length==_beginterritories); 
        require(Rounds[_rID].teamXaddr[msg.sender]==0);  
        
        uint i;
        for (i =0 ; i<territories.length;i++){
            require(territories[i]<uint16(2750));  
            require(getownership(territories[i])==uint16(0));  
        }

        _teamcnt+=1;  

        setownership(territories[0],_teamcnt);
        for (i =1 ; i<territories.length;i++){ 
            require(hasteamadjacency(territories[i],_teamcnt));  
            setownership(territories[i],_teamcnt);
        }
        

         
        Rounds[_rID].validrollsXaddr[msg.sender]+=_beginterritories;
        Rounds[_rID].validrollsXteam[_teamcnt]+=_beginterritories;
        
        
        Rounds[_rID].teamXaddr[msg.sender]=_teamcnt;  
        Rounds[_rID].nationnameXteam[_teamcnt]=name;
        Rounds[_rID].colorXteam[_teamcnt]=RGB;
        Rounds[_rID].iscolorregistered[RGB]=true;
        Rounds[_rID].teamcnt=_teamcnt;
        Rounds[_rID].isnameregistered[name]=true; 
        Rounds[_rID].pot+=msg.value;
        
        
         
        emit oncreatenation(
            nameXaddress[msg.sender],
            name,
            RGB,
            _teamcnt,
            territories,
            msg.sender);
    }
    
    
    function roll(uint16[] territories,uint16 team) 
    payable
    public
    {
        RequireHuman();
        require(isactive);
        
        require(team!=0);
        
        uint256 _rID = roundID;
        uint256 _now = block.timestamp;
        uint256 _roundstart = Rounds[_rID].roundstart;
        uint256 _trucetime = Rounds[_rID].trucetime;


        if (Rounds[_rID].teamXaddr[msg.sender]==0){  
            Rounds[_rID].teamXaddr[msg.sender]=team;
        }
        else{
            require(Rounds[_rID].teamXaddr[msg.sender]==team);  
        }


         
        
        
        require(msg.value==Rounds[_rID].price ); 
        
        uint16 _maxroll = Rounds[_rID].maxroll;
        seed = uint256(keccak256(abi.encodePacked((seed^block.timestamp))));  
        uint256 rolled = (seed % _maxroll)+1;  
        uint256 validrolls=0; 
        uint16[] memory territoriesconquered = new uint16[](_maxroll);
        
        if  (_roundstart+_trucetime<_now){ 
            for (uint i = 0 ; i<territories.length;i++){
                if (getownership(territories[i])==team){  
                    continue;
                }
                if (hasteamadjacency(territories[i],team)){ 
                    territoriesconquered[validrolls]=territories[i];
                    setownership(territories[i],team);  
                    validrolls+=1;
                    if (validrolls==rolled){ 
                        break;
                    }
                }
            }
        }
        else{ 
            require(Rounds[_rID].validrollsXteam[team]<Rounds[_rID].maxextensiontruce);  
            for  (i = 0 ; i<territories.length;i++){
                if (getownership(territories[i])!=0){  
                    continue;
                }
                if (hasteamadjacency(territories[i],team)){ 
                    territoriesconquered[validrolls]=territories[i];
                    setownership(territories[i],team);  
                    validrolls+=1;
                    if (validrolls==rolled){ 
                        break;
                    }
                }
            }
        }

        Rounds[_rID].validrollsXaddr[msg.sender]+=validrolls;
        Rounds[_rID].validrollsXteam[team]+=validrolls;
        
        uint256 refund;
        if (validrolls<rolled){
            refund = ((rolled-validrolls)*msg.value)/rolled;
        }
        Rounds[_rID].pot+=msg.value-refund;
        if (refund>0){
            msg.sender.transfer(refund);
        }
        
        
         
        emit onroll(
            nameXaddress[msg.sender],
            Rounds[_rID].nationnameXteam[team],
            rolled,
            team,
            territoriesconquered,
            msg.sender
            );
    }


    function endround()
     
    public
    {
        RequireHuman();
        require(isactive);
        
        uint256 _rID = roundID;
        require(Rounds[_rID].teamcnt>0);  

        uint256 _pot = Rounds[_rID].pot;
        uint256 fee =_pot/20;  
        uint256 nextpot = _pot/20;  
        uint256 finalpot = _pot-fee-nextpot;  
        
        
        uint256 _roundstart=Rounds[_rID].roundstart;
        uint256 _now=block.timestamp;
        require(_roundstart+Rounds[_rID].trucetime<_now); 


        uint256[] memory _owners_ = new uint256[](86);
        for (uint16 i = 0;i<86;i++){  
            _owners_[i]=Rounds[_rID].owners[i];
        }

        uint16 t;
        uint16 team;
        uint16 j;
        for ( i = 1; i<uint16(2750);i++){  
            t=getownership2(i,_owners_[i/32]);
            if (t!=uint16(0)){
                team=t;
                j=i+1;
                break;
            }
        }
        
        for ( i = j; i<uint16(2750);i++){  
            t=getownership2(i,_owners_[i/32]);
            if(t>0){
                if(t!=team){
                    require(false);
                }
            }
        }
        Rounds[_rID].teampotshare[team]=finalpot;  
        Rounds[_rID].winner=Rounds[_rID].nationnameXteam[team];
        
        
        admin.transfer(fee);
        
        
         
        _rID+=1;
        Rounds[_rID].trucetime =trucetime;
        Rounds[_rID].roundstart =block.timestamp;
        Rounds[_rID].beginterritories =beginterritories; 
        Rounds[_rID].maxroll = maxroll;
        Rounds[_rID].pot = nextpot;
        Rounds[_rID].price = price;
        Rounds[_rID].maxextensiontruce = maxextensiontruce;
        roundID=_rID;
        
        emit onendround();
    }


    function withdraw() 
    public
    {
        RequireHuman();
        uint256 balance;
        uint256 _roundID=roundID;
        balance=getbalance(_roundID);
        playerlastroundwithdrawn[msg.sender]=_roundID-1;
        if (balance>0){
            msg.sender.transfer(balance);
        }
    }
    
    
    function buyname( string _name)
    public
    payable
    {
        RequireHuman();
        
        
        bytes32 name=nameFilter(_name);
        address prevowner=ownerXname[name];
        require(prevowner!=msg.sender);
        uint256 buyprice = 3*priceXname[name]/2;  
        if (3 finney > buyprice){  
            buyprice = 3 finney;
        }
        require(msg.value>=buyprice);
        
        uint256 fee;
        uint256 topot;
        uint256 reimbursement;
        
        
        if (prevowner==address(0)){  
            Rounds[roundID].pot+=msg.value ;   
        }
        else{
            fee = buyprice/20;  
            topot = msg.value-buyprice; 
            reimbursement=buyprice-fee;  
            if (topot>0){
            Rounds[roundID].pot+=topot;
            }
        }
        

        nameXaddress[prevowner]='';  
        ownerXname[name]=msg.sender;  
        priceXname[name]=msg.value;  
        bytes32 prevname = nameXaddress[msg.sender];
        nameXaddress[msg.sender]=name;  
        
        emit onbuyname(
            name,
            msg.value,
            prevname,
            msg.sender
            );
            
        if (fee>0){
        admin.transfer(fee);
            
        }
        if (reimbursement>0){
        prevowner.transfer(reimbursement);
        }
    }
    
    
    function switchname(bytes32 name)  
    public
    {
        require(ownerXname[name]==msg.sender); 
        nameXaddress[msg.sender]=name; 
    }
    
    
    function clearname()  
    public
    {
        bytes32 empty;
        nameXaddress[msg.sender]=empty;
    }
    

     


    function getownership(uint16 terr) 
    private 
    view
    returns(uint16)
    { 
         
        return(uint16((Rounds[roundID].owners[terr/32]&(255*2**(8*(uint256(terr%32)))))/(2**(uint256(terr)%32*8))));
    }


    function getownership2(uint16 terr,uint256 ownuint)  
    private 
    pure
    returns(uint16)
    { 
         
        return(uint16((ownuint&255*2**(8*(uint256(terr)%32)))/(2**(uint256(terr)%32*8))));
    } 


    function setownership(uint16 terr, uint16 team)
    private
    {  
         
        Rounds[roundID].owners[terr/32]=(Rounds[roundID].owners[terr/32]&(115792089237316195423570985008687907853269984665640564039457584007913129639935-(255*(2**(8*(uint256(terr)%32))))))|(uint256(team)*2**((uint256(terr)%32)*8));
    }


    function areadjacent(uint16 terr1, uint16 terr2) 
    private
    view
    returns(bool)
    {
        for (uint i=0;i<19;i++){
            if (adjacencies[terr1][i]==terr2){ 
                return true;
            }
            if (adjacencies[terr1][i]==0){  
                return false;
            }
        }
        return false;
    } 


    function hasteamadjacency(uint16 terr,uint16 team) 
    private
    view
    returns(bool)
    {
        for (uint i = 0; i<adjacencies[terr].length;i++){
            if (getownership(adjacencies[terr][i])==team){
                return true;
            }
        }
        return false;
    }
    
    
     
    function RequireHuman()
    private
    view
    {
        uint256  size;
        address addr = msg.sender;
        
        assembly {size := extcodesize(addr)}
        require(size == 0 );
    }

    

    
    function colorfilter(uint256 RGB)
    public
    pure
    returns(uint256)
    {
         
         
        RGB=RGB&14737632;

         
        require(RGB!=12632256);
        require(RGB!=14704640);
        require(RGB!=14729344);
        require(RGB!=8421504);
        require(RGB!=224);
        require(RGB!=8404992);


        return(RGB);
    }


    function getbalance(uint rID)
    public
    view
    returns(uint256)
    {
        uint16 team;
        uint256 balance;
        for (uint i = playerlastroundwithdrawn[msg.sender]+1;i<rID;i++){
            if (Rounds[i].validrollsXaddr[msg.sender]==0){  
                continue;
            }
            
            team=Rounds[i].teamXaddr[msg.sender];
            
            balance += (Rounds[i].teampotshare[team]*Rounds[i].validrollsXaddr[msg.sender])/Rounds[i].validrollsXteam[team];
        }
        return balance;
    }
     
     
    function nameFilter(string _input)  
    public
    pure
    returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        require (_length <= 32 && _length > 0, "string must be between 1 and 64 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        
         
        for (uint256 i = 0; i < _length; i++)
        {
                require
                (
                     
                    _temp[i] == 0x20 || 
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) 
                );
                 
                if (_temp[i] == 0x20){
                    
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                }
            }
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
    
    
     
    function readowners()
    view
    public
    returns(uint256[101])
    {
        return(Rounds[roundID].owners);
    }
    
    
    function readownerXname(string name)
    view
    public
    returns(address)
    {
        return(ownerXname[nameFilter(name)]);
    }
    
    
    function readisnameregistered(string name)
    view
    public
    returns(bool)
    {
        return(Rounds[roundID].isnameregistered[nameFilter(name)]);
    }
    
    
    function readnameXaddress(address addr)
    view
    public
    returns(bytes32)
    {
        return(nameXaddress[addr]);
    }
    
    
    function readpriceXname(string name)
    view
    public
    returns(uint256)
    {
        return(priceXname[nameFilter(name)]*3/2);
    }
    
    
    function readteamXaddr(address adr)
    view
    public
    returns(uint16){
        return(Rounds[roundID].teamXaddr[adr]);
    }
    
    
    function readvalidrollsXteam(uint16 tim)
    view
    public
    returns(uint256){
        return(Rounds[roundID].validrollsXteam[tim]);
    }
    
    
    function readvalidrollsXaddr(address adr)
    view
    public
    returns(uint256){
        return(Rounds[roundID].validrollsXaddr[adr]);
    }
    
    
    function readnationnameXteam()
    view
    public
    returns(bytes32[256]){
        bytes32[256] memory temp;
        for (uint16 i = 0; i<256; i++){
            temp[i]=Rounds[roundID].nationnameXteam[i];
        }
        return(temp);
    }
    
    
    function readcolorXteam()
    view
    public
    returns(uint256[256]){
        uint256[256] memory temp;
        for (uint16 i = 0; i<256; i++){
            temp[i]=Rounds[roundID].colorXteam[i];
        }
        return(temp);
    }
    
    
    function readiscolorregistered(uint256 rgb)
    view
    public
    returns(bool){
        return(Rounds[roundID].iscolorregistered[colorfilter(rgb)]);
    }
    
    
    function readhistoricalrounds()
    view
    public
    returns(bytes32[]){
        bytes32[] memory asdfg=new bytes32[](2*roundID-2);
        for (uint256 i = 1;i<roundID;i++){
            asdfg[2*i]=Rounds[roundID].winner;
            asdfg[2*i+1]=bytes32(Rounds[roundID].pot);
        }
        return asdfg;
    }
    

     
    
   

     
    function addadjacencies(uint16[] indexes,uint16[] numvals,uint16[] adjs)
    public
    {   
        require(msg.sender==admin);
        require(!isactive);
        
        uint cnt=0;
        for (uint i = 0; i<indexes.length;i++){
            for (uint j = 0;j<numvals[i];j++){
                adjacencies[indexes[i]][j]=adjs[cnt];
                cnt++;
            }
        }   
    }


     
    function finishedloading()
    public
    {
        require(msg.sender==admin);
        require(!isactive);
        
        isactive=true;
        
         
        roundID=1;
        uint256 _rID=roundID;
         
        Rounds[_rID].roundstart =block.timestamp;
        Rounds[_rID].beginterritories =beginterritories; 
        Rounds[_rID].maxroll = maxroll;
        Rounds[_rID].trucetime = trucetime;
        Rounds[_rID].price = price;
        Rounds[_rID].maxextensiontruce = maxextensiontruce;
    }
    
    
     
    function changesettings(  uint16 _beginterritories, uint16 _maxroll,uint256 _trucetime,uint256 _price,uint256 _maxextensiontruce)
    public
    {
        require(msg.sender==admin);
         
        beginterritories = _beginterritories ;
        maxroll = _maxroll;
        trucetime = _trucetime;
        price = _price;
        maxextensiontruce = _maxextensiontruce;
        
    }


     

     
    struct RoundData{
        
         
         
         
         
        uint256[101] owners;
        
        
        mapping(address=>uint16) teamXaddr;  
         
        mapping(uint16=>uint256) validrollsXteam;  
        mapping(address=>uint256) validrollsXaddr;  
        mapping(uint16=>uint256) teampotshare;  
        mapping(uint16=>bytes32) nationnameXteam;
        uint256 pot;
        
         
        mapping(uint16=>uint256) colorXteam;
         
        mapping(uint256=>bool) iscolorregistered;
        
        
        mapping(bytes32=>bool) isnameregistered;  
        
        
         
        uint16 teamcnt;
        
        
         
        uint256 roundstart;
        
        
         
        uint16 beginterritories;  
        uint16 maxroll; 
        uint256 trucetime;
        uint256 price;
        uint256 maxextensiontruce;
        
        bytes32 winner;
    }


     

     
     event oncreatenation(
        bytes32 leadername,
        bytes32 nationname,
        uint256 color,
        uint16 team,
        uint16[] territories,
        address addr
     );

     event onroll(
        bytes32 playername,
        bytes32 nationname,
        uint256 rolled,
        uint16 team,
        uint16[] territories,
        address addr
     );
     event onbuyname(
        bytes32 newname,
        uint256 price,
        bytes32 prevname,
        address addr
     );
     event onendround(
     );
}