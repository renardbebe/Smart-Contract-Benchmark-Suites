 

pragma solidity ^0.4.23;

 

library ECRecoveryLibrary {

     
    function recover(bytes32 hash, bytes sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (sig.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
             
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
         
         
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            hash
        );
    }
}

 
library SafeMathLibrary {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract Pausable is Ownable {
    bool public paused = false;

    event Pause();

    event Unpause();

     
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
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

interface TokenReceiver {
    function tokenFallback(address _from, uint _value) external returns(bool);
}

contract Token is Pausable {
    using SafeMathLibrary for uint;

    using ECRecoveryLibrary for bytes32;

    uint public decimals = 18;

    mapping (address => uint) balances;

    mapping (address => mapping (address => uint)) allowed;

    mapping(bytes => bool) signatures;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint amount, uint fee);

    function () {
        revert();
    }

     
    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint _value) whenNotPaused public returns (bool) {
        require(_to != address(0) && _value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        callTokenFallback(_to, msg.sender, _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function delegatedTransfer(bytes _signature, address _to, uint _value, uint _fee, uint _nonce) whenNotPaused public returns (bool) {
        require(_to != address(0) && signatures[_signature] == false);

        bytes32 hashedTx = hashDelegatedTransfer(_to, _value, _fee, _nonce);
        address from = hashedTx.recover(_signature);

        require(from != address(0) && _value.add(_fee) <= balances[from]);

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        signatures[_signature] = true;

        callTokenFallback(_to, from, _value);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit DelegatedTransfer(from, _to, msg.sender, _value, _fee);
        return true;
    }

    function hashDelegatedTransfer(address _to, uint _value, uint _fee, uint _nonce) public view returns (bytes32) {
           
        return keccak256(bytes4(0x45b56ba6), address(this), _to, _value, _fee, _nonce);
    }

     
    function transferFrom(address _from, address _to, uint _value) whenNotPaused public returns (bool ok) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        callTokenFallback(_to, _from, _value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint _value) whenNotPaused public returns (bool ok) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant public returns (uint) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) whenNotPaused public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function callTokenFallback(address _contract, address _from, uint _value) internal {
        if (isContract(_contract)) {
            require(contracts[_contract] != address(0) && balances[_contract] >= contractHoldBalance);
            TokenReceiver receiver = TokenReceiver(_contract);
            require(receiver.tokenFallback(_from, _value));
        }
    }

    function isContract(address _address) internal view returns(bool) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return (length > 0);
    }

     
    mapping (address => address) contracts;

    uint contractHoldBalance = 500 * 10 ** decimals;

    function setContractHoldBalance(uint _value) whenNotPaused onlyOwner public returns(bool) {
        contractHoldBalance = _value;
        return true;
    }

    function register(address _contract) whenNotPaused public returns(bool) {
        require(isContract(_contract) && contracts[_contract] == address(0) && balances[msg.sender] >= contractHoldBalance);
        balances[msg.sender] = balances[msg.sender].sub(contractHoldBalance);
        balances[_contract] = balances[_contract].add(contractHoldBalance);
        contracts[_contract] = msg.sender;
        return true;
    }

    function unregister(address _contract) whenNotPaused public returns(bool) {
        require(isContract(_contract) && contracts[_contract] == msg.sender);
        balances[_contract] = balances[_contract].sub(contractHoldBalance);
        balances[msg.sender] = balances[msg.sender].add(contractHoldBalance);
        delete contracts[_contract];
        return true;
    }
}

contract CATT is Token {
    string public name = "Content Aggregation Transfer Token";

    string public symbol = "CATT";

    uint public totalSupply = 5000000000 * 10 ** decimals;

    constructor() public {
        balances[owner] = totalSupply;
    }
}