 

pragma solidity ^0.4.11;

library SafeMath {
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC223Compliant {
    function tokenFallback(address _from, uint _value, bytes _data) {}
}

contract EtheraffleLOT is ERC223Compliant {
    using SafeMath for uint;

    string    public name;
    string    public symbol;
    bool      public frozen;
    uint8     public decimals;
    address[] public freezers;
    address   public etheraffle;
    uint      public totalSupply;

    mapping (address => uint) public balances;
    mapping (address => bool) public canFreeze;

    event LogFrozenStatus(bool status, uint atTime);
    event LogFreezerAddition(address newFreezer, uint atTime);
    event LogFreezerRemoval(address freezerRemoved, uint atTime);
    event LogEtheraffleChange(address prevER, address newER, uint atTime);
    event LogTransfer(address indexed from, address indexed to, uint value, bytes indexed data);

     
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
     
    modifier onlyFreezers() {
        require(canFreeze[msg.sender]);
        _;
    }
     
    modifier onlyIfNotFrozen() {
        require(!frozen);
        _;
    }
     
    function EtheraffleLOT(address _etheraffle, uint _supply) {
        freezers.push(_etheraffle);
        name                   = "Etheraffle LOT";
        symbol                 = "LOT";
        decimals               = 6;
        etheraffle             = _etheraffle;
        totalSupply            = _supply * 10 ** uint256(decimals);
        balances[_etheraffle]  = totalSupply;
        canFreeze[_etheraffle] = true;
    }
     
    function transfer(address _to, uint _value, bytes _data) onlyIfNotFrozen external {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]        = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223Compliant receiver = ERC223Compliant(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        LogTransfer(msg.sender, _to, _value, _data);
    }
     
    function transfer(address _to, uint _value) onlyIfNotFrozen external {
        uint codeLength;
        bytes memory empty;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]        = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223Compliant receiver = ERC223Compliant(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        LogTransfer(msg.sender, _to, _value, empty);
    }
     
    function balanceOf(address _owner) constant external returns (uint balance) {
        return balances[_owner];
    }
     
    function setFrozen(bool _status) external onlyFreezers returns (bool) {
        frozen = _status;
        LogFrozenStatus(frozen, now);
        return frozen;
    }
     
    function addFreezer(address _new) external onlyEtheraffle {
        freezers.push(_new);
        canFreeze[_new] = true;
        LogFreezerAddition(_new, now);
    }
     
    function removeFreezer(address _freezer) external onlyEtheraffle {
        require(canFreeze[_freezer]);
        canFreeze[_freezer] = false;
        for(uint i = 0; i < freezers.length - 1; i++)
            if(freezers[i] == _freezer) {
                freezers[i] = freezers[freezers.length - 1];
                break;
            }
        freezers.length--;
        LogFreezerRemoval(_freezer, now);
    }
     
    function setEtheraffle(address _new) external onlyEtheraffle {
        LogEtheraffleChange(etheraffle, _new, now);
        etheraffle = _new;
    }
     
    function () external payable {
        revert();
    }
     
    function selfDestruct() external onlyEtheraffle {
        require(frozen);
        selfdestruct(etheraffle);
    }
}