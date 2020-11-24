 

pragma solidity ^0.4.16;

contract VCCT {
     
    string public name = "VCCT";
     
    string public symbol = "VCCT";
     
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    bool public lockAll = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event OwnerUpdate(address _prevOwner, address _newOwner);

    address public owner;
     
    address internal newOwner = 0x0;
    mapping(address => bool) public frozens;
    mapping(address => uint256) public balanceOf;

    constructor() public {
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address tOwner) onlyOwner public {
        require(owner != tOwner);
        newOwner = tOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner && newOwner != 0x0);
        owner = newOwner;
        newOwner = 0x0;
        emit OwnerUpdate(owner, newOwner);
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozens[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function freezeAll(bool lock) onlyOwner public {
        lockAll = lock;
    }

    function contTransfer(address _to, uint256 weis) onlyOwner public {
        _transfer(this, _to, weis);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function _transfer(address _from, address _to, uint _value) internal {
         
        require(!lockAll);
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        require(!frozens[_from]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

}