 

pragma solidity ^0.4.25;

contract Token {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address receiver)public returns(uint);
}

 
 

contract Axioms {
    Airdrop [] public airdrops;
    address owner;
    uint idCounter;
    
     
    constructor () public {
        owner = msg.sender;
    }
    
    
     
    modifier minEth {
        require(msg.value >= 2000); 
        _;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    struct Airdrop {
        uint id;
        uint tokenAmount;
        string name;
        uint countDown;
        address distributor;
        Token tokenSC;
        mapping(address => address) uniqueAirdrop;
    }

     
   function addNewAirdrop(
     uint _tokenAmount,
     string _name,
     uint _countDown,
     address  _smartContract
   
   )
     public
     minEth
     payable
   {
       Token t = Token(_smartContract);
       if(t.balanceOf(this)>=_tokenAmount){
        uint lastIndex = airdrops.length++;
        Airdrop storage airdrop = airdrops[lastIndex];
        airdrop.id =idCounter;
        airdrop.tokenAmount = _tokenAmount;
        airdrop.name=_name;
        airdrop.countDown=_countDown;
        airdrop.distributor = msg.sender;
        airdrop.tokenSC = Token(_smartContract);
        airdrop.uniqueAirdrop[msg.sender]=_smartContract;
        idCounter = airdrop.id+1;
       }else revert('Air Drop not added, Please make sure you send your ERC20 tokens to the smart contract before adding new airdrop');
   }

     
     
     
     
     
    function distributeVariable(
        uint index,
        address[] _addrs,
        uint[] _vals
    )
        public
        onlyOwner
    {
        if(timeGone(index)==true) {
            Airdrop memory airdrop = airdrops[index];
            for(uint i = 0; i < _addrs.length; ++i) {
                airdrop.tokenSC.transfer(_addrs[i], _vals[i]);
            }
        } else revert("Distribution Failed: Countdown not finished yet");
    }

     
     
     
     
     
    function distributeFixed(
        uint index,
        address[] _addrs,
        uint _amoutToEach
    )
        public
        onlyOwner
    {
         if(timeGone(index)==true) {
            Airdrop memory airdrop = airdrops[index];
            for(uint i = 0; i < _addrs.length; ++i) {
                airdrop.tokenSC.transfer(_addrs[i], _amoutToEach);
            }
        } else revert("Distribution Failed: Countdown not finished yet");
    }

     
    function refoundTokens(
        uint index,
        address receiver,
        address sc
    )
        public
        onlyOwner
    {   
        
        Airdrop memory airdrop = airdrops[index];
        if(isAirDropUnique(index,receiver,sc)==true){
        airdrop.tokenSC.transfer(airdrop.distributor,airdrop.tokenAmount);
        }else revert();
        
    }
    
     
    function refundLeftOverEth (
        uint index,
        uint amount,
        address reciever,
        address sc
    )
        public 
        onlyOwner
    {
         Airdrop memory airdrop = airdrops[index];
         if(isAirDropUnique(index,reciever,sc)==true){
        airdrop.distributor.transfer(amount);
         }else revert();
    }
      
     
     
    function timeGone(uint index) private view returns(bool){
        Airdrop memory airdrop = airdrops[index];
        uint timenow=now;
        if ( airdrop.countDown <timenow){
            return (true);
        }else return (false);
      }
      
     
    function isAirDropUnique(uint index, address receiver, address sc) private view returns(bool){
        Airdrop storage airdrop = airdrops[index];
        if(airdrop.uniqueAirdrop[receiver]==sc){
            return true;
        }else return false; 
    }

     
    function transferOwnership(address _newOwner) public onlyOwner(){
        require(_newOwner != address(0));
        owner = _newOwner;
    }
}