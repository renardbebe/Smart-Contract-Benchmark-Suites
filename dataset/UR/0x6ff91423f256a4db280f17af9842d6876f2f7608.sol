 

 

pragma solidity ^0.5.0;

 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.4;


 
interface IGovernanceRegistry {
    
     
    function isSignee(address account) external view returns (bool);

     
    function isVault(address account) external view returns (bool) ;

}

 

pragma solidity 0.5.4;




 
contract GovernanceRegistry is Ownable {

    struct Actor {
        bytes32 name;
        bool enrolled;
    }

     
    mapping (address => Actor) public signees;

     
    mapping (address => Actor) public vaults;

     
    function addSignee(address signee, bytes32 name) external onlyOwner{
        signees[signee] = Actor(name,true);
    }

     
    function removeSignee(address signee) external onlyOwner {
        signees[signee] = Actor(bytes32(0),false);
    }

     
    function addVault(address vault, bytes32 name) external onlyOwner {
        vaults[vault] = Actor(name,true);
    }

     
    function removeVault(address vault) external onlyOwner {
        vaults[vault] = Actor(bytes32(0),false);
    }

     
    function isSignee(address account) external view returns (bool) {
        return signees[account].enrolled;
    }

     
    function isVault(address account) external view returns (bool) {
        return vaults[account].enrolled;
    }

}