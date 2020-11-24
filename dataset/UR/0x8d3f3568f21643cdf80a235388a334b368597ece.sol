 

pragma solidity ^0.5.12;

 
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract IPO  {
    using SafeMath for uint;
     
    
    address payable public hubFundAdmin;
    uint256 public payoutPot;
     
    PlincInterface constant hub_ = PlincInterface(0xd5D10172e8D8B84AC83031c16fE093cba4c84FC6); 
     
    mapping(uint256 => uint256)public  bondsOutstanding;  
    uint256 public totalSupplyBonds;  
    mapping(address => uint256)public  playerVault;  
    mapping(uint256 => uint256) public  totalsupplyStake;  
    
    mapping(uint256 => uint256)public  pendingFills;  
    
    mapping(address => uint256)public  playerId;  
    mapping(uint256 => uint256)public  IPOtoID;  
    mapping(uint256 => address payable)public  IdToAdress;  
    uint256  public nextPlayerID;
    
    uint256 public nextIPO; 
    mapping(uint256 => address)public  IPOcreator; 
    mapping(uint256 => bool)public  IPOhasTarget;
    mapping(uint256 => uint256)public  IPOtarget;
    mapping(uint256 => bool)public  IPOisActive;
    mapping(uint256 => bytes32)public  IPOinfo;
    uint256 public openingFee;
    
     
    mapping(uint256 =>  mapping(address => uint256))public  IPOpurchases; 
    mapping(uint256 =>  mapping(uint256 => address))public  IPOadresslist; 
    mapping(uint256 => uint256)public  IPOnextAddressPointer;
    mapping(uint256 => uint256)public  IPOamountFunded;
    mapping(uint256 =>  uint256)public  IdVaultedEths; 
    
     
    mapping(address =>  mapping(uint256 => uint256))public  funcAmount;
    mapping(address =>  mapping(uint256 => address))public  funcAddress;
     
    mapping(uint256 => uint256)public  IPOprofile;
    mapping(uint256 => bool)public  UIblacklist;
    
     
    function setFees(uint256 amount) public {
        require(msg.sender == hubFundAdmin);
        openingFee = amount;
    }
    
    function registerIPO(address payable creator,bool hasTarget, uint256 target, bytes32 info) public payable updateAccount(playerId[msg.sender]){
        uint256 next = nextIPO;
        uint256 value = msg.value;
        require(value >= openingFee);
        playerVault[hubFundAdmin] = playerVault[hubFundAdmin] + value; 
         
        
           IPOtoID[next] = nextPlayerID;  
           IdToAdress[nextPlayerID] = creator;  
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            
         
        IPOcreator[next] = creator;
         
        IPOhasTarget[next] = hasTarget;
         
        IPOtarget[next] = target;
         
        IPOinfo[next] = info;
        
         
        IPOisActive[next] = true;
         
        nextIPO++;
        emit IPOCreated(creator,hasTarget,target);
    }
    function fundIPO(uint256 IPOidentifier) public payable updateAccount(playerId[msg.sender])updateAccount(IPOtoID[IPOidentifier]){
         
        uint256 value = msg.value;
        address payable sender = msg.sender;
        require(IPOisActive[IPOidentifier] == true);
         
        if(IPOhasTarget[IPOidentifier] == true)
        {
             
            if(IPOamountFunded[IPOidentifier].add(value)  > IPOtarget[IPOidentifier]){
                 
                playerVault[sender] = playerVault[sender].add(IPOamountFunded[IPOidentifier].add(value)).sub(IPOtarget[IPOidentifier]);
                 
                value = IPOtarget[IPOidentifier].sub(IPOamountFunded[IPOidentifier]);
            }
        }
          
        if(playerId[sender] == 0){
           playerId[sender] = nextPlayerID;
           IdToAdress[nextPlayerID] = sender;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
         
        bondsOutstanding[playerId[sender]] = bondsOutstanding[playerId[sender]].add(value);
         
        bondsOutstanding[IPOtoID[IPOidentifier]] = bondsOutstanding[IPOtoID[IPOidentifier]].add(value.div(10));
         
        totalSupplyBonds = totalSupplyBonds.add(value).add(value.div(10));
         
        IPOpurchases[IPOidentifier][sender] =  IPOpurchases[IPOidentifier][sender].add(value);
         
        IPOadresslist[IPOidentifier][IPOnextAddressPointer[IPOidentifier]] = sender;
         
        IPOnextAddressPointer[IPOidentifier] = IPOnextAddressPointer[IPOidentifier].add(1);
         
        IPOamountFunded[IPOidentifier] = IPOamountFunded[IPOidentifier].add(value);
         
        hub_.buyBonds.value(value)(0x2e66aa088ceb9Ce9b04f6B9B7482fBe559732A70) ;
        emit IPOFunded(sender,value,IPOidentifier);
    }
     
    function giftExcessBonds(address payable _IPOidentifier) public payable updateAccount(playerId[msg.sender])updateAccount(playerId[_IPOidentifier]){
         
        uint256 value = msg.value;
        address payable sender = msg.sender;
        
          
        if(playerId[sender] == 0){
           playerId[sender] = nextPlayerID;
           IdToAdress[nextPlayerID] = sender;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
             
        if(playerId[_IPOidentifier] == 0){
           playerId[_IPOidentifier] = nextPlayerID;
           IdToAdress[nextPlayerID] = _IPOidentifier;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
         
        bondsOutstanding[playerId[sender]] = bondsOutstanding[playerId[sender]].add(value);
         
        bondsOutstanding[playerId[_IPOidentifier]] = bondsOutstanding[playerId[_IPOidentifier]].add(value.div(10));
         
        totalSupplyBonds = totalSupplyBonds.add(value).add(value.div(10));
         
        hub_.buyBonds.value(value)(0x2e66aa088ceb9Ce9b04f6B9B7482fBe559732A70) ;
        emit payment(sender,IdToAdress[playerId[_IPOidentifier]],value );
    }
    function RebatePayment(address payable _IPOidentifier, uint256 refNumber) public payable updateAccount(playerId[msg.sender])updateAccount(playerId[_IPOidentifier]){
         
        uint256 value = msg.value;
        address payable sender = msg.sender;
        
          
        if(playerId[sender] == 0){
           playerId[sender] = nextPlayerID;
           IdToAdress[nextPlayerID] = sender;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
             
        if(playerId[_IPOidentifier] == 0){
           playerId[_IPOidentifier] = nextPlayerID;
           IdToAdress[nextPlayerID] = _IPOidentifier;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
         
        bondsOutstanding[playerId[sender]] = bondsOutstanding[playerId[sender]].add(value);
         
        bondsOutstanding[playerId[_IPOidentifier]] = bondsOutstanding[playerId[_IPOidentifier]].add(value.div(10));
         
        totalSupplyBonds = totalSupplyBonds.add(value).add(value.div(10));
         
        hub_.buyBonds.value(value)(0x2e66aa088ceb9Ce9b04f6B9B7482fBe559732A70) ;
        emit payment(sender,IdToAdress[playerId[_IPOidentifier]],value );
         
        funcAmount[_IPOidentifier][refNumber] = value;
        funcAmount[_IPOidentifier][refNumber] = value;
    }
    function giftAll(address payable _IPOidentifier) public payable updateAccount(playerId[msg.sender])updateAccount(playerId[_IPOidentifier]){
         
        uint256 value = msg.value;
        address payable sender = msg.sender;
        
          
        if(playerId[sender] == 0){
           playerId[sender] = nextPlayerID;
           IdToAdress[nextPlayerID] = sender;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
             
        if(playerId[_IPOidentifier] == 0){
           playerId[_IPOidentifier] = nextPlayerID;
           IdToAdress[nextPlayerID] = _IPOidentifier;
           fetchdivs(nextPlayerID);
           nextPlayerID++;
            }
         
        bondsOutstanding[playerId[_IPOidentifier]] = bondsOutstanding[playerId[_IPOidentifier]].add(value);
         
        bondsOutstanding[playerId[_IPOidentifier]] = bondsOutstanding[playerId[_IPOidentifier]].add(value.div(10));
         
        totalSupplyBonds = totalSupplyBonds.add(value).add(value.div(10));
         
        hub_.buyBonds.value(value)(0x2e66aa088ceb9Ce9b04f6B9B7482fBe559732A70) ;
        emit payment(sender,IdToAdress[playerId[_IPOidentifier]],value );
    }
     
    function changeIPOstate(uint256 IPOidentifier, bool state) public {
        address sender = msg.sender;
        require(sender == IPOcreator[IPOidentifier]);
         
        IPOisActive[IPOidentifier] = state;
    }
    function changeUIblacklist(uint256 IPOidentifier, bool state) public {
        
        address sender = msg.sender;
        require(sender == hubFundAdmin);
         
        UIblacklist[IPOidentifier] = state;
    }
    function changeIPOinfo(uint256 IPOidentifier, bytes32 info) public {
        address sender = msg.sender;
        require(sender == IPOcreator[IPOidentifier]);
         
        IPOinfo[IPOidentifier] = info;
        
    }
     
    function RaiseProfile(uint256 IPOidentifier) public payable updateAccount(playerId[msg.sender])updateAccount(playerId[hubFundAdmin]){
         
        uint256 value = msg.value;
        address sender = msg.sender;
        require(IPOisActive[IPOidentifier] == true);
        
         
        bondsOutstanding[playerId[sender]] = bondsOutstanding[playerId[sender]].add(value);
         
        bondsOutstanding[playerId[hubFundAdmin]] = bondsOutstanding[playerId[hubFundAdmin]].add(value.div(10));
         
        IPOprofile[IPOidentifier] = IPOprofile[IPOidentifier].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value).add(value.div(10));
         
        hub_.buyBonds.value(value)(0x2e66aa088ceb9Ce9b04f6B9B7482fBe559732A70) ;
    }
     
    uint256 public pointMultiplier = 10e18;
    struct Account {
        uint256 owned;
        uint256 lastDividendPoints;
        }
    mapping(uint256=>Account)public  accounts;
    
    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    function dividendsOwing(uint256 account) public view returns(uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(accounts[account].lastDividendPoints);
        return (bondsOutstanding[account] * newDividendPoints) / pointMultiplier;
    }
    function fetchdivs(uint256 toupdate) public updateAccount(toupdate){}
    
    
    modifier updateAccount(uint256 account) {
        uint256 owing = dividendsOwing(account);
        if(owing > 0) {
            
            unclaimedDividends = unclaimedDividends.sub(owing);
            pendingFills[account] = pendingFills[account].add(owing);
        }
        accounts[account].lastDividendPoints = totalDividendPoints;
        _;
        }
    function () external payable{}  
    function vaultToWallet(uint256 _ID) public {
        
        address payable _sendTo = IdToAdress[_ID];
        require(playerVault[IdToAdress[_ID]] > 0);
         
        uint256 value = playerVault[IdToAdress[_ID]];
        playerVault[_sendTo] = 0;
        _sendTo.transfer(value);
        emit cashout(_sendTo,value);
    }
    
    function fillBonds (uint256 bondsOwner) updateAccount(bondsOwner) public {
        uint256 pendingz = pendingFills[bondsOwner];
        require(bondsOutstanding[bondsOwner] > 1000 && pendingz > 1000);
        if(pendingz > bondsOutstanding[bondsOwner]){
             
            payoutPot = payoutPot.add(pendingz.sub(bondsOutstanding[bondsOwner]));
            pendingz = bondsOutstanding[bondsOwner];
            
        }
         
         
        pendingFills[bondsOwner] = 0;
         
        bondsOutstanding[bondsOwner] = bondsOutstanding[bondsOwner].sub(pendingz);
         
        totalSupplyBonds = totalSupplyBonds.sub(pendingz);
         
        playerVault[IdToAdress[bondsOwner]] = playerVault[IdToAdress[bondsOwner]].add(pendingz);
         
        IdVaultedEths[bondsOwner] = IdVaultedEths[bondsOwner].add(pendingz);
        
    }
    function setHubAuto(uint256 percentage) public{
        require(msg.sender == hubFundAdmin);
        hub_.setAuto(percentage);
    }
    function fetchHubVault() public{
        
        uint256 value = hub_.playerVault(address(this));
        require(value >0);
        require(msg.sender == hubFundAdmin);
        hub_.vaultToWallet();
        payoutPot = payoutPot.add(value);
    }
    function fetchHubPiggy() public{
        
        uint256 value = hub_.piggyBank(address(this));
        require(value >0);
        hub_.piggyToWallet();
        payoutPot = payoutPot.add(value);
    }
    function potToPayout() public {
        uint256 value = payoutPot;
        payoutPot = 0;
        require(value > 1 finney);
        totalDividendPoints = totalDividendPoints.add(value.mul(pointMultiplier).div(totalSupplyBonds));
        unclaimedDividends = unclaimedDividends.add(value);
        emit bondsMatured(value);
    }    
    constructor()
        public
        
    {
        hubFundAdmin = 0x2e66aa088ceb9Ce9b04f6B9B7482fBe559732A70; 
        playerId[hubFundAdmin] = 1;
        IdToAdress[1] = hubFundAdmin;
        nextPlayerID = 2;
        hub_.setAuto(10);
        openingFee = 0.1 ether;
    }

 
    function getIPOpurchases(uint256 IPOidentifier) public view returns(address[] memory _funders, uint256[] memory owned){
        uint i;
          address[] memory _locationOwner = new address[](IPOnextAddressPointer[IPOidentifier]);  
          uint[] memory _locationData = new uint[](IPOnextAddressPointer[IPOidentifier]);  
            bool checkpoint;
          for(uint x = 0; x < IPOnextAddressPointer[IPOidentifier]; x+=1){
              checkpoint = false;
                for(uint y = 0; y < IPOnextAddressPointer[IPOidentifier]; y+=1)
                {
                    if(_locationOwner[y] ==IPOadresslist[IPOidentifier][i])
                    {
                        checkpoint = true;
                    }
                }
                    if (checkpoint == false)
                    {
                    _locationOwner[i] = IPOadresslist[IPOidentifier][i];
                    _locationData[i] = IPOpurchases[IPOidentifier][IPOadresslist[IPOidentifier][i]];
                    }
              i+=1;
            }
          
          return (_locationOwner,_locationData);
    }
    
    function getHubInfo() public view returns(uint256 piggy){
        uint256 _piggy = hub_.piggyBank(address(this));
        return(_piggy);
    }
    function getPlayerInfo() public view returns(address[] memory _Owner, uint256[] memory locationData,address[] memory infoRef ){
          uint i;
          address[] memory _locationOwner = new address[](nextPlayerID);  
          uint[] memory _locationData = new uint[](nextPlayerID*4);  
          address[] memory _info = new address[](nextPlayerID*2);
           
          uint y;
          uint z;
          for(uint x = 0; x < nextPlayerID; x+=1){
            
             
                _locationOwner[i] = IdToAdress[i];
                _locationData[y] = bondsOutstanding[i];
                _locationData[y+1] = dividendsOwing(i);
                _locationData[y+2] = pendingFills[i];
                _locationData[y+3] = playerVault[IdToAdress[i]];
                _info[z] = IdToAdress[i];
                _info[z+1] = IdToAdress[i];
                
                 
              y += 4;
              z += 2;
              i+=1;
            }
          
          return (_locationOwner,_locationData, _info);
        }
        function getIPOInfo(address user) public view returns(address[] memory _Owner, uint256[] memory locationData , bool[] memory states, bytes32[] memory infos){
          uint i;
          address[] memory _locationOwner = new address[](nextIPO);  
          uint[] memory _locationData = new uint[](nextIPO * 6);  
          bool[] memory _states = new bool[](nextIPO * 3);  
          bytes32[] memory _infos = new bytes32[](nextIPO); 
          uint y;
          uint z;
          for(uint x = 0; x < nextIPO; x+=1){
            
                _locationOwner[i] = IPOcreator[i];
                _locationData[y] = IPOtarget[i];
                _locationData[y+1] = IPOamountFunded[i];
                _locationData[y+2] = IPOprofile[i];
                _locationData[y+3] = IPOpurchases[i][user];
                _locationData[y+4] = IdVaultedEths[IPOtoID[i]];
                _locationData[y+5] = IPOtoID[i];
                _states[z] = IPOhasTarget[i];
                _states[z+1] = IPOisActive[i];
                _states[z+2] = UIblacklist[i];
                _infos[i] = IPOinfo[i];
                
              y += 6;
              z += 3;
              i+=1;
            }
          
          return (_locationOwner,_locationData, _states, _infos);
        }
   
  
event IPOFunded(address indexed Funder, uint256 indexed amount, uint256 indexed IPOidentifier);
event cashout(address indexed player , uint256 indexed ethAmount);
event bondsMatured(uint256 indexed amount);
event IPOCreated(address indexed owner, bool indexed hastarget, uint256 indexed target);
event payment(address indexed sender,address indexed receiver, uint256 indexed amount);

}

interface PlincInterface {
    
    function IdToAdress(uint256 index) external view returns(address);
    function nextPlayerID() external view returns(uint256);
    function bondsOutstanding(address player) external view returns(uint256);
    function playerVault(address player) external view returns(uint256);
    function piggyBank(address player) external view returns(uint256);
    function vaultToWallet() external ;
    function piggyToWallet() external ;
    function setAuto (uint256 percentage)external ;
    function buyBonds( address referral)external payable ;
}