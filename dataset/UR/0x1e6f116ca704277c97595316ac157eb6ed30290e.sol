 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    constructor(address _owner) public {
        owner = _owner;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract BatchTransfer is Ownable {

     
    constructor () public Ownable(msg.sender) {}

    function batchTransfer(address[] _destinations, uint256[] _amounts) 
        public
        ownerOnly()
        {
            require(_destinations.length == _amounts.length);

            for (uint i = 0; i < _destinations.length; i++) {
                if (_destinations[i] != 0x0) {
                    _destinations[i].transfer(_amounts[i]);
                }
            }
        }

    function batchTransfer(address[] _destinations, uint256 _amount) 
        public
        ownerOnly()
        {
            require(_destinations.length > 0);

            for (uint i = 0; i < _destinations.length; i++) {
                if (_destinations[i] != 0x0) {
                    _destinations[i].transfer(_amount);
                }
            }
        }
        
    function transfer(address _destination, uint256 _amount)
        public
        ownerOnly()
        {
            require(_destination != 0x0 && _amount > 0);
            _destination.transfer(_amount);
        }

    function transferAllToOwner()
        public
        ownerOnly()
        {
            address(this).transfer(address(this).balance);
        }
        
    function() public payable { }
}