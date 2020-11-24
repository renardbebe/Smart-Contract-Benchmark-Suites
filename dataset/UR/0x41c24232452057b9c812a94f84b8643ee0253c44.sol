 

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.4;


contract DAORegistry is Ownable {

    event Propose(address indexed _avatar);
    event Register(address indexed _avatar, string _name);
    event UnRegister(address indexed _avatar);

    mapping(string=>bool) private registry;

    constructor(address _owner) public {
        transferOwnership(_owner);
    }

    function propose(address _avatar) public {
        emit Propose(_avatar);
    }

    function register(address _avatar, string memory _name) public onlyOwner {
        require(!registry[_name]);
        registry[_name] = true;
        emit Register(_avatar, _name);
    }

    function unRegister(address _avatar) public onlyOwner {
        emit UnRegister(_avatar);
    }

     
    function isRegister(string memory _name) public view returns(bool) {
        return registry[_name];
    }

}