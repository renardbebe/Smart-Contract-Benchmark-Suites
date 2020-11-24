 

pragma solidity ^0.4.19;

 
 
 

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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


interface AHSInterface {
    function registerHandle(bytes32 _base, bytes32 _handle, address _addr) public payable;
    function transferBase(bytes32 _base, address _newAddress) public;
    function findAddress(bytes32 _base, bytes32 _handle) public view returns(address);
    function isRegistered(bytes32 _base) public view returns(bool);
    function doesOwn(bytes32 _base, address _addr) public view returns(bool);
}


contract PHS is Ownable {

    AHSInterface public ahs;
    bytes32 public ethBase;  

    mapping (bytes32 => bool) public ethHandleRegistred;
    mapping (address => mapping (bytes32 => bool)) public ownsEthHandle;


    event HandleTransfered(bytes32 _handle, address indexed _to);

    function PHS(AHSInterface _ahs, bytes32 _ethBase) public {
        ahs = _ahs;
        ethBase = _ethBase;
    }

    function registerEthHandle(bytes32 _handle, address _addr) public payable {
        require(_addr != address(0));
        if (ethHandleRegistred[_handle] && ownsEthHandle[msg.sender][_handle]) {
            ahs.registerHandle(ethBase, _handle, _addr);
        }
        if (!ethHandleRegistred[_handle]) {
            ethHandleRegistred[_handle] = true;
            ownsEthHandle[msg.sender][_handle] = true;
            ahs.registerHandle(ethBase, _handle, _addr);
        } else {
            revert();
        }
    }

    function transferEthHandleOwnership(bytes32 _handle, address _addr) public {
        require(ownsEthHandle[msg.sender][_handle]);
        ownsEthHandle[msg.sender][_handle] = false;
        ownsEthHandle[_addr][_handle] = true;
    }

    function getEthBase() public view returns(bytes32) {
        return ethBase;
    }

    function ethHandleIsRegistered(bytes32 _handle) public view returns(bool) {
        return ethHandleRegistred[_handle];
    }

    function findAddress(bytes32 _handle) public view returns(address) {
        address addr = ahs.findAddress(ethBase, _handle);
        return addr;
    }

    function doesOwnEthHandle(bytes32 _handle, address _addr) public view returns(bool) {
        return ownsEthHandle[_addr][_handle];
    }

    function transferBaseOwnership() public {
        require(msg.sender == owner);
        ahs.transferBase(ethBase, owner);
    }

    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }

}