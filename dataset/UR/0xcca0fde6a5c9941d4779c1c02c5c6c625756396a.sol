 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
    
     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
        assert(_a == _b * c + _a % _b);  

        return c;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
 
 
 
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract IMCToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address externalContractAddress;


     
    constructor() public {
        symbol = "IMC";
        name = "IMC";
        decimals = 8;
        _totalSupply = 1000000000 * (10 ** uint(decimals));
        balances[owner] = _totalSupply;
        
        emit Transfer(address(0), owner, _totalSupply);
    }

     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal{
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);

         
        uint previousBalance = balances[_from].add(balances[_to]);

         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);

         
        emit Transfer(_from, _to, _value);

         
        assert(balances[_from].add(balances[_to]) == previousBalance);
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
         

        if (msg.sender == owner) {
             
            _transfer(msg.sender, _to, _value);

            return true;
        } else {
             
            require(msg.sender == externalContractAddress);

            _transfer(owner, _to, _value);

            return true;
        }
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        
        if (_from == msg.sender) {
             
            _transfer(_from, _to, _value);

        } else {
             
            require(allowed[_from][msg.sender] >= _value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

            _transfer(_from, _to, _value);

        }

        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
             
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function approveContractCall(address _contractAddress) public onlyOwner returns (bool){
        externalContractAddress = _contractAddress;
        
        return true;
    }

     
    function () public payable {
        revert();
    }
}

 
 
 
contract IMCIssuingRecord is Owned{
    using SafeMath for uint;

     
    event IssuingRecordAdd(uint _date, bytes32 _hash, uint _depth, uint _userCount, uint _token, string _fileFormat, uint _stripLen);

     
    IMCToken public imcToken;

     
    address platformAddr;

     
    struct RecordInfo {
        uint date;   
        bytes32 hash;   
        uint depth;  
        uint userCount;  
        uint token;  
        string fileFormat;  
        uint stripLen;  
    }
    
     
    mapping(uint => RecordInfo) public issuingRecord;
    
     
    uint public userCount;
    
     
    uint public totalIssuingBalance;
    
     
    constructor(address _tokenAddr, address _platformAddr) public{
         
        imcToken = IMCToken(_tokenAddr);

         
        platformAddr = _platformAddr;
    }
    
     
    function modifyPlatformAddr(address _addr) public onlyOwner {
        platformAddr = _addr;
    }

     
    function sendTokenToPlatform(uint _tokens) internal returns (bool) {

        imcToken.transfer(platformAddr, _tokens);
        
        return true;
    }

     
    function issuingRecordAdd(uint _date, bytes32 _hash, uint _depth, uint _userCount, uint _token, string _fileFormat, uint _stripLen) public onlyOwner returns (bool) {
         
        require(!(issuingRecord[_date].date > 0));

         
        userCount = userCount.add(_userCount);

         
        totalIssuingBalance = totalIssuingBalance.add(_token);
        
         
        issuingRecord[_date] = RecordInfo(_date, _hash, _depth, _userCount, _token, _fileFormat, _stripLen);

         
        sendTokenToPlatform(_token);

        emit IssuingRecordAdd(_date, _hash, _depth, _userCount, _token, _fileFormat, _stripLen);
        
        return true;
        
    }

}