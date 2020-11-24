 

pragma solidity 0.4.18;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract FHFTokenInterface {
     
    string public standard = 'Token 0.1';
    string public name = 'Forever Has Fallen';
    string public symbol = 'FC';
    uint8 public decimals = 18;

    function approveCrowdsale(address _crowdsaleAddress) external;
    function balanceOf(address _address) public constant returns (uint256 balance);
    function vestedBalanceOf(address _address) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract CrowdsaleParameters {
     
     
     

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
    }

    uint256 public maximumICOCap = 350e6;

     
     
     
    uint256 public generalSaleStartDate = 1525777200;
    uint256 public generalSaleEndDate = 1529406000;

     
     
    uint32 internal vestingTeam = 1592564400;
     
    uint32 internal vestingBounty = 1529406000;

     
     
     


     
     
     

    AddressTokenAllocation internal generalSaleWallet = AddressTokenAllocation(0x265Fb686cdd2f9a853c519592078cC4d1718C15a, 350e6);
    AddressTokenAllocation internal communityReserve =  AddressTokenAllocation(0x76d472C73681E3DF8a7fB3ca79E5f8915f9C5bA5, 450e6);
    AddressTokenAllocation internal team =              AddressTokenAllocation(0x05d46150ceDF59ED60a86d5623baf522E0EB46a2, 170e6);
    AddressTokenAllocation internal advisors =          AddressTokenAllocation(0x3d5fa25a3C0EB68690075eD810A10170e441413e, 48e5);
    AddressTokenAllocation internal bounty =            AddressTokenAllocation(0xAc2099D2705434f75adA370420A8Dd397Bf7CCA1, 176e5);
    AddressTokenAllocation internal administrative =    AddressTokenAllocation(0x438aB07D5EC30Dd9B0F370e0FE0455F93C95002e, 76e5);

    address internal playersReserve = 0x8A40B0Cf87DaF12C689ADB5C74a1B2f23B3a33e1;
}

contract FHFToken is Owned, CrowdsaleParameters, FHFTokenInterface {
     
    mapping (address => uint256) private balances;               
    mapping (address => uint256) private balancesEndIcoFreeze;   
    mapping (address => uint256) private balances2yearFreeze;   
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => mapping (address => bool)) private allowanceUsed;


     
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event VestingTransfer(address indexed from, address indexed to, uint256 value, uint256 vestingTime);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Issuance(uint256 _amount);  
    event Destruction(uint256 _amount);  
    event NewFHFToken(address _token);

     
    uint256 public totalSupply = 0;  

     
    function FHFToken() public {
        owner = msg.sender;

        mintToken(generalSaleWallet);
        mintToken(communityReserve);
        mintToken(team);
        mintToken(advisors);
        mintToken(bounty);
        mintToken(administrative);

        NewFHFToken(address(this));
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     
    function approveCrowdsale(address _crowdsaleAddress) external onlyOwner {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint amount = generalSaleWallet.amount * exponent;

        allowed[generalSaleWallet.addr][_crowdsaleAddress] = amount;
        Approval(generalSaleWallet.addr, _crowdsaleAddress, amount);
    }

     
    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

     
    function vestedBalanceOf(address _address) public constant returns (uint256 balance) {
        if (now < vestingBounty) {
            return balances[_address] - balances2yearFreeze[_address] - balancesEndIcoFreeze[_address];
        }
        if (now < vestingTeam) {
            return balances[_address] - balances2yearFreeze[_address];
        } else {
            return balances[_address];
        }
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mintToken(AddressTokenAllocation tokenAllocation) internal {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint mintedAmount = tokenAllocation.amount * exponent;

         
        balances[tokenAllocation.addr] += mintedAmount;
        totalSupply += mintedAmount;

         
        Issuance(mintedAmount);
        Transfer(address(this), tokenAllocation.addr, mintedAmount);
    }

     
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        require(_value == 0 || allowanceUsed[msg.sender][_spender] == false);

        allowed[msg.sender][_spender] = _value;
        allowanceUsed[msg.sender][_spender] = false;
        Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _currentValue, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
        require(allowed[msg.sender][_spender] == _currentValue);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
         
        require(vestedBalanceOf(msg.sender) >= _value);

         
         
        balances[msg.sender] -= _value;

         
        balances[_to] += _value;

         
        if ((msg.sender == bounty.addr) && (now < vestingBounty)) {
            balancesEndIcoFreeze[_to] += _value;
        }
        if ((msg.sender == team.addr) && (now < vestingTeam)) {
            balances2yearFreeze[_to] += _value;
        }

        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
         
        require(vestedBalanceOf(_from) >= _value);

         
        require(_value <= allowed[_from][msg.sender]);

         
         
        balances[_from] -= _value;
         
         
        balances[_to] += _value;

         
         
        allowed[_from][msg.sender] -= _value;

         
        if ((_from == bounty.addr) && (now < vestingBounty)) {
            balancesEndIcoFreeze[_to] += _value;
        }
        if ((_from == team.addr) && (now < vestingTeam)) {
            balances2yearFreeze[_to] += _value;
        }

        Transfer(_from, _to, _value);
        allowanceUsed[_from][msg.sender] = true;

        return true;
    }

     
    function() public {
    }
}