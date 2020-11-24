 

pragma solidity ^0.4.11;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

}


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() {
        owner = msg.sender;
    }

     
     
    function transferOwnership(address _newOwner) onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }

     
    function acceptOwnership() {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Administrable is Ownable {

    event AdminstratorAdded(address adminAddress);
    event AdminstratorRemoved(address adminAddress);

    mapping (address => bool) public administrators;

    modifier onlyAdministrator() {
        require(administrators[msg.sender] || owner == msg.sender);  
        _;
    }

     
     
    function addAdministrators(address _adminAddress) onlyOwner {
        administrators[_adminAddress] = true;
        AdminstratorAdded(_adminAddress);
    }

     
     
    function removeAdministrators(address _adminAddress) onlyOwner {
        delete administrators[_adminAddress];
        AdminstratorRemoved(_adminAddress);
    }
}

 
contract GimliToken is ERC20, SafeMath, Ownable {


     

    uint8 public constant decimals = 8;
    string public constant name = "Gimli Token";
    string public constant symbol = "GIM";
    string public constant version = 'v1';

     
    uint256 public constant UNIT = 10**uint256(decimals);
    uint256 constant MILLION_GML = 10**6 * UNIT;  
     
    uint256 public constant TOTAL_SUPPLY = 150 * MILLION_GML;  

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

    bool public transferable = false;

     


     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(transferable);

        require(balances[msg.sender] >= _value && _value >=0);


        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(transferable);

        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0);

        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract GimliCrowdsale is SafeMath, GimliToken {

    address public constant MULTISIG_WALLET_ADDRESS = 0xc79ab28c5c03f1e7fbef056167364e6782f9ff4f;
    address public constant LOCKED_ADDRESS = 0xABcdEFABcdEFabcdEfAbCdefabcdeFABcDEFabCD;

     
    uint256 public constant CROWDSALE_AMOUNT = 80 * MILLION_GML;  
    uint256 public constant START_DATE = 1505736000;  
    uint256 public constant END_DATE = 1508500800;  
    uint256 public constant CROWDSALE_PRICE = 700;  
    uint256 public constant VESTING_1_AMOUNT = 10 * MILLION_GML;  
    uint256 public constant VESTING_1_DATE = 1537272000;  
    uint256 public constant VESTING_2_AMOUNT = 30 * MILLION_GML;  
    uint256 public constant VESTING_2_DATE = 1568808000;  
    bool public vesting1Withdrawn = false;
    bool public vesting2Withdrawn = false;
    bool public crowdsaleCanceled = false;
    uint256 public soldAmount;  
    uint256 public paidAmount;  

     
    function() payable {
        require(!crowdsaleCanceled);

        require(msg.value > 0);
         
        require(block.timestamp >= START_DATE && block.timestamp <= END_DATE);

         
        uint256 quantity = safeDiv(safeMul(msg.value, CROWDSALE_PRICE), 10**(18-uint256(decimals)));
        require(safeSub(balances[this], quantity) >= 0);

        require(MULTISIG_WALLET_ADDRESS.send(msg.value));

         
        balances[this] = safeSub(balances[this], quantity);
        balances[msg.sender] = safeAdd(balances[msg.sender], quantity);
        soldAmount = safeAdd(soldAmount, quantity);
        paidAmount = safeAdd(paidAmount, msg.value);

        Transfer(this, msg.sender, quantity);
    }

     
    function  closeCrowdsale() onlyOwner {
         
        require(block.timestamp > END_DATE || crowdsaleCanceled || balances[this] == 0);

         
        transferable = true;

         
        if (balances[this] > 0) {
            uint256 amount = balances[this];
            balances[MULTISIG_WALLET_ADDRESS] = safeAdd(balances[MULTISIG_WALLET_ADDRESS], amount);
            balances[this] = 0;
            Transfer(this, MULTISIG_WALLET_ADDRESS, amount);
        }
    }

     
    function cancelCrowdsale() onlyOwner {
        crowdsaleCanceled = true;
    }

     
     
     
     
    function preAllocate(address _to, uint256 _value, uint256 _price) onlyOwner {
        require(block.timestamp < START_DATE);

        balances[this] = safeSub(balances[this], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        soldAmount = safeAdd(soldAmount, _value);
        paidAmount = safeAdd(paidAmount, _price);

        Transfer(this, _to, _value);
    }

     
     
     
    function releaseVesting(address _destination) onlyOwner returns (bool success) {
        if (block.timestamp > VESTING_1_DATE && vesting1Withdrawn == false) {
            balances[LOCKED_ADDRESS] = safeSub(balances[LOCKED_ADDRESS], VESTING_1_AMOUNT);
            balances[_destination] = safeAdd(balances[_destination], VESTING_1_AMOUNT);
            vesting1Withdrawn = true;
            Transfer(LOCKED_ADDRESS, _destination, VESTING_1_AMOUNT);
            return true;
        }
        if (block.timestamp > VESTING_2_DATE && vesting2Withdrawn == false) {
            balances[LOCKED_ADDRESS] = safeSub(balances[LOCKED_ADDRESS], VESTING_2_AMOUNT);
            balances[_destination] = safeAdd(balances[_destination], VESTING_2_AMOUNT);
            vesting2Withdrawn = true;
            Transfer(LOCKED_ADDRESS, _destination, VESTING_2_AMOUNT);
            return true;
        }
        return false;
    }

     
     
     
    function transferOtherERC20Token(address tokenAddress, uint256 amount)
      onlyOwner returns (bool success)
    {
         
        require(tokenAddress != address(this) || transferable);
        return ERC20(tokenAddress).transfer(owner, amount);
    }
}

 
contract Gimli is GimliCrowdsale, Administrable {

    address public streamerContract;
    uint256 public streamerContractMaxAmount;

    event StreamerContractChanged(address newContractAddress, uint256 newMaxAmount);

     
    function Gimli() {
         
        balances[MULTISIG_WALLET_ADDRESS] = safeAdd(balances[MULTISIG_WALLET_ADDRESS], TOTAL_SUPPLY - CROWDSALE_AMOUNT - VESTING_1_AMOUNT - VESTING_2_AMOUNT);
         
        balances[this] = CROWDSALE_AMOUNT;
         
        balances[LOCKED_ADDRESS] = VESTING_1_AMOUNT + VESTING_2_AMOUNT;
         
        totalSupply = TOTAL_SUPPLY;
    }

     
     
     
    function setStreamerContract(
        address _contractAddress,
        uint256 _maxAmount) onlyAdministrator
    {
         
        require(_maxAmount == 0 || streamerContractMaxAmount == 0);

        streamerContract = _contractAddress;
        streamerContractMaxAmount = _maxAmount;

        StreamerContractChanged(streamerContract, streamerContractMaxAmount);
    }

     
     
     
     
     
    function transferGIM(address _from, address _to, uint256 _amount) returns (bool success) {
        require(msg.sender == streamerContract);
        require(tx.origin == _from);
        require(_amount <= streamerContractMaxAmount);

        if (balances[_from] < _amount || _amount <= 0)
            return false;

        balances[_from] = safeSub(balances[_from], _amount);
        balances[_to] = safeAdd(balances[_to], _amount);

        Transfer(_from, _to, _amount);

        return true;
    }



}