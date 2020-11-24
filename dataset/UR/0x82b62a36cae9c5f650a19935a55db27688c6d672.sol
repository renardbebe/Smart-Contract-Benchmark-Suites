 

pragma solidity ^0.4.20;

contract Ownable {
    
    address public owner;
    
    event OwnershipTransferred(address indexed from, address indexed to);
    
    
     
    function Ownable() public {
        owner = 0x202abc6cf98863ee0126c182ca325a33a867acba ;
    }


     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0)
            && _newOwner != owner 
        );
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
     
    modifier whenPaused() {
        require(paused);
        _;
    }
    
     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }
    
     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}


contract TokenTransferInterface {
    function transfer(address _to, uint256 _value) public;
}


contract SelfDropCYFM is Pausable {
    
    mapping (address => bool) public addrHasClaimedTokens;
    
    TokenTransferInterface public constant token = TokenTransferInterface(0x32b87fb81674aa79214e51ae42d571136e29d385);
    
    uint256 public tokensToSend = 5000e18;
    
    
    function changeTokensToSend(uint256 _value) public onlyOwner {
        require(_value != tokensToSend);
        require(_value > 0);
        tokensToSend = (_value * (10 ** 18));
    }
    
    
    function() public payable whenNotPaused {
        require(!addrHasClaimedTokens[msg.sender]);
        require(msg.value == 0);
        addrHasClaimedTokens[msg.sender] = true;
        token.transfer(msg.sender, tokensToSend);
    }
}