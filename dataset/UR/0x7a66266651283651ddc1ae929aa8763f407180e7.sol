 

pragma solidity ^0.4.22;

 
 
 
 
contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 _value) public returns (bool);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
 
 
contract ERC223Interface {
    uint public totalSupply;
    function transfer(address to, uint value, bytes data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
 
contract owned {
    address public owner;

    function  owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}
 
contract ContractReceiver {
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

         
    }
}
 

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
contract TimeVaultInterface is ERC20Interface, ERC223Interface {
    function timeVault(address who) public constant returns (uint);
    function getNow() public constant returns (uint);
    function transferByOwner(address to, uint _value, uint timevault) public returns (bool);
}
 
contract ELTTokenType {
    uint public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;

    mapping(address => uint) timevault;
    mapping(address => mapping(address => uint)) allowed;

     
    bool public released;

     
    uint public globalTimeVault;

    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract ERC20Token is ERC20Interface, ERC223Interface, ELTTokenType {
    using SafeMath for uint;

    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data, false);
        }
        else {
            return transferToAddress(_to, _value, _data, false);
        }
    }

     
    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly
        {
         
            length := extcodesize(_addr)
        }
        return (length > 0);
    }


     
    function transferToAddress(address _to, uint _value, bytes _data, bool withAllowance) private returns (bool success) {
        transferIfRequirementsMet(msg.sender, _to, _value, withAllowance);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data, bool withAllowance) private returns (bool success) {
        transferIfRequirementsMet(msg.sender, _to, _value, withAllowance);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
     
     
     
    function checkTransferRequirements(address _to, uint _value) private view {
        require(_to != address(0));
        require(released == true);
        require(now > globalTimeVault);
        if (timevault[msg.sender] != 0)
        {
            require(now > timevault[msg.sender]);
        }
        require(balanceOf(msg.sender) >= _value);
    }

     
    function transferIfRequirementsMet(address _from, address _to, uint _value, bool withAllowances) private {
        checkTransferRequirements(_to, _value);
        if ( withAllowances)
        {
            require (_value <= allowed[_from][msg.sender]);
        }
        balances[_from] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }

     
    function transferFrom(address from, address to, uint value) public returns (bool) {
        bytes memory empty;
        if (isContract(to)) {
            return transferToContract(to, value, empty, true);
        }
        else {
            return transferToAddress(to, value, empty, true);
        }
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return true;
    }
}
contract TimeVaultToken is  owned, TimeVaultInterface, ERC20Token {

    function transferByOwner(address to, uint value, uint earliestReTransferTime) onlyOwner public returns (bool) {
        transfer(to, value);
        timevault[to] = earliestReTransferTime;
        return true;
    }

    function timeVault(address owner) public constant returns (uint earliestTransferTime) {
        return timevault[owner];
    }

    function getNow() public constant returns (uint blockchainTimeNow) {
        return now;
    }

}
contract StandardToken is TimeVaultToken {
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}
contract StandardTokenExt is StandardToken {

     
    function isToken() public pure returns (bool weAre) {
        return true;
    }
}
contract OwnershipTransferrable is TimeVaultToken {

    event OwnershipTransferred(address indexed _from, address indexed _to);


    function transferOwnership(address newOwner) onlyOwner public {
        transferByOwner(newOwner, balanceOf(newOwner), 0);
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

}
contract VersionedToken is owned {
    address public upgradableContractAddress;

     
    function VersionedToken(address initialImplementation) public {
        upgradableContractAddress = initialImplementation;
    }

     

    function upgradeToken(address newImplementation) onlyOwner public {
        upgradableContractAddress = newImplementation;
    }

     
    function() public {
        address upgradableContractMem = upgradableContractAddress;
        bytes memory functionCall = msg.data;

        assembly {
         
            let functionCallSize := mload(functionCall)

         
            let functionCallDataAddress := add(functionCall, 0x20)

         
            let functionCallResult := delegatecall(gas, upgradableContractMem, functionCallDataAddress, functionCallSize, 0, 0)

            let freeMemAddress := mload(0x40)

            switch functionCallResult
            case 0 {
             
                revert(freeMemAddress, 0)
            }
            default {
             
                returndatacopy(freeMemAddress, 0x0, returndatasize)
             
                return (freeMemAddress, returndatasize)
            }
        }
    }
}
contract ELTToken is VersionedToken, ELTTokenType {
    string public name;
    string public symbol;

    function ELTToken(address _tokenOwner, string _tokenName, string _tokenSymbol, uint _totalSupply, uint _decimals, uint _globalTimeVaultOpeningTime, address _initialImplementation) VersionedToken(_initialImplementation)  public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint(decimals);
         
        balances[_tokenOwner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
        globalTimeVault = _globalTimeVaultOpeningTime;
        released = false;

    }
}
contract ELTTokenImpl is StandardTokenExt {
     
    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;
    string public symbol;
     bool private adminReturnStatus ;

     
    function releaseTokenTransfer(bool _value) onlyOwner public {
        released = _value;
    }

    function setGlobalTimeVault(uint _globalTimeVaultOpeningTime) onlyOwner public {
        globalTimeVault = _globalTimeVaultOpeningTime;
    }
     function admin(string functionName, string p1, string p2, string p3) onlyOwner public returns (bool result) {
         
        adminReturnStatus = (bytes(functionName).length + bytes(p1).length + bytes(p2).length + bytes(p3).length) != 0;

        return adminReturnStatus ;
    }
     
    function setTokenInformation(string _tokenName, string _tokenSymbol) onlyOwner public {
        name = _tokenName;
        symbol = _tokenSymbol;
        emit UpdatedTokenInformation(name, symbol);
    }
}