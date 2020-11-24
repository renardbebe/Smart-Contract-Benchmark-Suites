 

pragma solidity ^0.4.19;

contract SmzTradingContract
{
    address public constant RECEIVER_ADDRESS = 0xf3eB3CA356c111ECb418D457e55A3A3D185faf61;
    uint256 public constant ACCEPTED_AMOUNT = 3 ether;
    uint256 public RECEIVER_PAYOUT_THRESHOLD = 100 ether;
    
    address public constant END_ADDRESS = 0x3559e34004b944906Bc727a40d7568a98bDc42d3;
    uint256 public constant END_AMOUNT = 0.39 ether;
    
    bool public ended = false;
    
    mapping(address => bool) public addressesAllowed;
    mapping(address => bool) public addressesDeposited;
    
     
    address public manager;
    
    function SmzTradingContract() public
    {
        manager = msg.sender;
    }
    function setManager(address _newManager) external
    {
        require(msg.sender == manager);
        manager = _newManager;
    }
    
    function () payable external
    {
         
        if (msg.sender == END_ADDRESS && msg.value == END_AMOUNT)
        {
            ended = true;
            RECEIVER_ADDRESS.transfer(this.balance);
            return;
        }
        
         
        require(!ended);
        
         
        require(msg.value == ACCEPTED_AMOUNT);
        
         
        require(addressesAllowed[msg.sender] == true);
        
         
        require(addressesDeposited[msg.sender] == false);
        addressesDeposited[msg.sender] = true;
        
         
         
        addressesAllowed[msg.sender] = false;
        
         
         
        if (this.balance >= RECEIVER_PAYOUT_THRESHOLD)
        {
            RECEIVER_ADDRESS.transfer(this.balance);
        }
    }
    
     
    function addAllowedAddress(address _allowedAddress) public
    {
        require(msg.sender == manager);
        addressesAllowed[_allowedAddress] = true;
    }
    function removeAllowedAddress(address _disallowedAddress) public
    {
        require(msg.sender == manager);
        addressesAllowed[_disallowedAddress] = false;
    }
    
    function addMultipleAllowedAddresses(address[] _allowedAddresses) external
    {
        require(msg.sender == manager);
        for (uint256 i=0; i<_allowedAddresses.length; i++)
        {
            addressesAllowed[_allowedAddresses[i]] = true;
        }
    }
    function removeMultipleAllowedAddresses(address[] _disallowedAddresses) external
    {
        require(msg.sender == manager);
        for (uint256 i=0; i<_disallowedAddresses.length; i++)
        {
            addressesAllowed[_disallowedAddresses[i]] = false;
        }
    }
}