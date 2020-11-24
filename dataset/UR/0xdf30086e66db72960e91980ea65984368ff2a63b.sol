 

pragma solidity ^0.4.24;

 

 
library SafeMath {

     
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


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract ERC223 {
    uint public totalSupply;

     
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

         
    }
}


 
contract GanapatiToken is ERC223, Ownable {
    using SafeMath for uint256;

    string public constant name = "G8C";
    string public constant symbol = "GAEC";
    uint8 public constant decimals = 8;
    uint256 public totalSupply = 7000000000000 * 10 ** 8;

     
     
    bool public mintingFinished = false;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
        
     
    mapping( address => bool ) public whiteList;

    event Mint(address indexed to, uint256 amount);
    event WhiteList(address indexed to, bool lock);
    event MintFinished();

     
    modifier isValidTransfer() {
        require(whiteList[msg.sender]);
        _;
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    constructor(address _owner) public {

         
        owner = _owner;

         
        address sale = 0x0301e60b967A088aAd7b6a0Dd3745608068c2574;
        balanceOf[sale] = totalSupply.mul(60).div(100);
        emit Transfer(0x0, sale, balanceOf[sale]);

         
        address team = 0x2EeF18D08B3278f7d9C76Ffb50C279490f54c6B3;
        balanceOf[team] = totalSupply.mul(15).div(100);
        emit Transfer(0x0, team, balanceOf[team]);

         
        address marketor = 0x76FA8c2952CcA46f874a598A6064C699C634CdAA;
        balanceOf[marketor] = totalSupply.mul(12).div(100);
        emit Transfer(0x0, marketor, balanceOf[marketor]);
        
         
        address advisor = 0xCCbc32321baeBa72f35590B084D38adC77e74123;
        balanceOf[advisor] = totalSupply.mul(10).div(100);
        emit Transfer(0x0, advisor, balanceOf[advisor]);

         
        address developer = 0x80459F7e1139d4cc97673131f2986000C024248e;
        balanceOf[developer] = totalSupply.mul(3).div(100);
        emit Transfer(0x0, developer, balanceOf[developer]);
    }

     
    function setUnLocked(address _to, bool _unLocked) onlyOwner public {
        whiteList[_to] = _unLocked;
        WhiteList(_to, _unLocked);
    }

    
    function transfer(address _to, uint _value, bytes _data) public isValidTransfer returns (bool success) {
        require(_value > 0 && _to != address(0));

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value) public isValidTransfer returns (bool success) {
        require(_value > 0 && _to != address(0));

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public isValidTransfer returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

     
    function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
        require(_unitAmount > 0);

        totalSupply = totalSupply.add(_unitAmount);
        balanceOf[_to] = balanceOf[_to].add(_unitAmount);
        emit Mint(_to, _unitAmount);
        emit Transfer(address(0), _to, _unitAmount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}