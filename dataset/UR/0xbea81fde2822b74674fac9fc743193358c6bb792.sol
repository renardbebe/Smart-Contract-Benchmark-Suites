 

pragma solidity 0.4.21;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Authorizable is Ownable {
    
    mapping(address => bool) public authorized;
    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

     
    function Authorizable() public {
        authorize(msg.sender);
    }

     
    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }

     
    function authorize(address _address) public onlyOwner {
        require(!authorized[_address]);
        emit AuthorizationSet(_address, true);
        authorized[_address] = true;
    }
     
    function deauthorize(address _address) public onlyOwner {
        require(authorized[_address]);
        emit AuthorizationSet(_address, false);
        authorized[_address] = false;
    }
}

 
contract Whitelist is Authorizable {
    mapping(address => bool) whitelisted;
    event AddToWhitelist(address _beneficiary);
    event RemoveFromWhitelist(address _beneficiary);
   
    function Whitelist() public {
        addToWhitelist(msg.sender);
    }
    
    
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address];
    }

 
    function addToWhitelist(address _beneficiary) public onlyAuthorized {
        require(!whitelisted[_beneficiary]);
        emit AddToWhitelist(_beneficiary);
        whitelisted[_beneficiary] = true;
    }
    
    function removeFromWhitelist(address _beneficiary) public onlyAuthorized {
        require(whitelisted[_beneficiary]);
        emit RemoveFromWhitelist(_beneficiary);
        whitelisted[_beneficiary] = false;
    }
}