 

pragma solidity ^0.4.11;

contract ERC223 {
    function tokenFallback(address _from, uint _value, bytes _data) public {}
}

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

contract EtheraffleFreeLOT is ERC223 {
    using SafeMath for uint;

    string    public name;
    string    public symbol;
    address[] public minters;
    uint      public redeemed;
    uint8     public decimals;
    address[] public destroyers;
    address   public etheraffle;
    uint      public totalSupply;

    mapping (address => uint) public balances;
    mapping (address => bool) public isMinter;
    mapping (address => bool) public isDestroyer;


    event LogMinterAddition(address newMinter, uint atTime);
    event LogMinterRemoval(address minterRemoved, uint atTime);
    event LogDestroyerAddition(address newDestroyer, uint atTime);
    event LogDestroyerRemoval(address destroyerRemoved, uint atTime);
    event LogMinting(address indexed toWhom, uint amountMinted, uint atTime);
    event LogDestruction(address indexed toWhom, uint amountDestroyed, uint atTime);
    event LogEtheraffleChange(address prevController, address newController, uint atTime);
    event LogTransfer(address indexed from, address indexed to, uint value, bytes indexed data);
     
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
     
    function EtheraffleFreeLOT(address _etheraffle, uint _amt) {
        name       = "Etheraffle FreeLOT";
        symbol     = "FreeLOT";
        etheraffle = _etheraffle;
        minters.push(_etheraffle);
        destroyers.push(_etheraffle);
        totalSupply              = _amt;
        balances[_etheraffle]    = _amt;
        isMinter[_etheraffle]    = true;
        isDestroyer[_etheraffle] = true;
    }
     
    function transfer(address _to, uint _value, bytes _data) external {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]        = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223 receiver = ERC223(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        LogTransfer(msg.sender, _to, _value, _data);
    }
     
    function transfer(address _to, uint _value) external {
        uint codeLength;
        bytes memory empty;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]        = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223 receiver = ERC223(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        LogTransfer(msg.sender, _to, _value, empty);
    }
     
    function balanceOf(address _owner) constant external returns (uint balance) {
        return balances[_owner];
    }
     
    function setEtheraffle(address _new) external onlyEtheraffle {
        LogEtheraffleChange(etheraffle, _new, now);
        etheraffle = _new;
    }
     
    function addMinter(address _new) external onlyEtheraffle {
        minters.push(_new);
        isMinter[_new] = true;
        LogMinterAddition(_new, now);
    }
     
    function removeMinter(address _minter) external onlyEtheraffle {
        require(isMinter[_minter]);
        isMinter[_minter] = false;
        for(uint i = 0; i < minters.length - 1; i++)
            if(minters[i] == _minter) {
                minters[i] = minters[minters.length - 1];
                break;
            }
        minters.length--;
        LogMinterRemoval(_minter, now);
    }
     
    function addDestroyer(address _new) external onlyEtheraffle {
        destroyers.push(_new);
        isDestroyer[_new] = true;
        LogDestroyerAddition(_new, now);
    }
     
    function removeDestroyer(address _destroyer) external onlyEtheraffle {
        require(isDestroyer[_destroyer]);
        isDestroyer[_destroyer] = false;
        for(uint i = 0; i < destroyers.length - 1; i++)
            if(destroyers[i] == _destroyer) {
                destroyers[i] = destroyers[destroyers.length - 1];
                break;
            }
        destroyers.length--;
        LogDestroyerRemoval(_destroyer, now);
    }
     
    function mint(address _to, uint _amt) external {
        require(isMinter[msg.sender]);
        totalSupply   = totalSupply.add(_amt);
        balances[_to] = balances[_to].add(_amt);
        LogMinting(_to, _amt, now);
    }
     
    function destroy(address _from, uint _amt) external {
        require(isDestroyer[msg.sender]);
        totalSupply     = totalSupply.sub(_amt);
        balances[_from] = balances[_from].sub(_amt);
        redeemed++;
        LogDestruction(_from, _amt, now);
    }
     
    function selfDestruct() external onlyEtheraffle {
        selfdestruct(etheraffle);
    }
     
    function () external payable {
        revert();
    }
}