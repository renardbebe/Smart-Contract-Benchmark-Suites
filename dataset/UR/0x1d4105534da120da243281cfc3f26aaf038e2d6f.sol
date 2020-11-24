 

pragma solidity ^0.4.15;

contract Utils {
     
    function Utils() internal {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


 
contract StandardERC20Token is IERC20Token, Utils {
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    


     
    function StandardERC20Token(string _name, string _symbol, uint8 _decimals) public{
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     function balanceOf(address _owner) constant returns (uint256) {
        return balanceOf[_owner];
    }
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowance[_owner][_spender];
    }
     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        require(balanceOf[_from] >= _value && _value > 0);
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

 
contract IOwned {
     
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract YooStop is Owned{

    bool public stopped = false;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public ownerOnly{
        stopped = true;
    }
    function start() public ownerOnly{
        stopped = false;
    }

}


contract YOOBAToken is StandardERC20Token, Owned,YooStop {



    uint256 constant public YOO_UNIT = 10 ** 18;
    uint256 public totalSupply = 100 * (10**8) * YOO_UNIT;

     
    uint256 constant public airdropSupply = 20 * 10**8 * YOO_UNIT;           
    uint256 constant public earlyInvestorSupply = 5 * 10**8 * YOO_UNIT;    
    uint256 constant public earlyCommunitySupply = 5 * 10**8 * YOO_UNIT;  
    uint256 constant public icoReservedSupply = 40 * 10**8 * YOO_UNIT;           
    uint256 constant public teamSupply = 12 * 10**8 * YOO_UNIT;          
    uint256 constant public ecosystemSupply = 18 * 10**8 * YOO_UNIT;          
    
    uint256  public tokensReleasedToIco = 0;   
    uint256  public tokensReleasedToEarlyInvestor = 0;   
    uint256  public tokensReleasedToTeam = 0;   
    uint256  public tokensReleasedToEcosystem = 0;   
    uint256  public currentSupply = 0;   

    
    
    address public airdropAddress;                                           
    address public yoobaTeamAddress;     
    address public earlyCommunityAddress;
    address public ecosystemAddress; 
    address public backupAddress;


    
    
    uint256 internal createTime = 1522261875;                                 
    uint256 internal teamTranchesReleased = 0;                           
    uint256 internal ecosystemTranchesReleased = 0;                           
    uint256 internal maxTranches = 16;       
    bool internal isInitAirdropAndEarlyAlloc = false;


     
    function YOOBAToken(address _airdropAddress, address _ecosystemAddress, address _backupAddress, address _yoobaTeamAddress,address _earlyCommunityAddress)
    StandardERC20Token("Yooba token", "YOO", 18) public
     {
        airdropAddress = _airdropAddress;
        yoobaTeamAddress = _yoobaTeamAddress;
        ecosystemAddress = _ecosystemAddress;
        backupAddress = _backupAddress;
        earlyCommunityAddress = _earlyCommunityAddress;
        createTime = now;
    }
    
    
     
     function initAirdropAndEarlyAlloc()   public ownerOnly stoppable returns(bool success){
         require(!isInitAirdropAndEarlyAlloc);
         require(airdropAddress != 0x0 && earlyCommunityAddress != 0x0);
         require((currentSupply + earlyCommunitySupply + airdropSupply) <= totalSupply);
         balanceOf[earlyCommunityAddress] += earlyCommunitySupply; 
         currentSupply += earlyCommunitySupply;
         Transfer(0x0, earlyCommunityAddress, earlyCommunitySupply);
        balanceOf[airdropAddress] += airdropSupply;       
        currentSupply += airdropSupply;
        Transfer(0x0, airdropAddress, airdropSupply);
        isInitAirdropAndEarlyAlloc = true;
        return true;
     }
    


     
    function transfer(address _to, uint256 _value) public stoppable returns (bool success) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
            return super.transferFrom(_from, _to, _value);
    }


     
    function releaseForEcosystem()   public ownerOnly stoppable returns(bool success) {
        require(now >= createTime + 12 weeks);
        require(tokensReleasedToEcosystem < ecosystemSupply);

        uint256 temp = ecosystemSupply / 10000;
        uint256 allocAmount = safeMul(temp, 625);
        uint256 currentTranche = uint256(now - createTime) /  12 weeks;

        if(ecosystemTranchesReleased < maxTranches && currentTranche > ecosystemTranchesReleased && (currentSupply + allocAmount) <= totalSupply) {
            ecosystemTranchesReleased++;
            balanceOf[ecosystemAddress] = safeAdd(balanceOf[ecosystemAddress], allocAmount);
            currentSupply += allocAmount;
            tokensReleasedToEcosystem = safeAdd(tokensReleasedToEcosystem, allocAmount);
            Transfer(0x0, ecosystemAddress, allocAmount);
            return true;
        }
        revert();
    }
    
        
    function releaseForYoobaTeam()   public ownerOnly stoppable returns(bool success) {
        require(now >= createTime + 12 weeks);
        require(tokensReleasedToTeam < teamSupply);

        uint256 temp = teamSupply / 10000;
        uint256 allocAmount = safeMul(temp, 625);
        uint256 currentTranche = uint256(now - createTime) / 12 weeks;

        if(teamTranchesReleased < maxTranches && currentTranche > teamTranchesReleased && (currentSupply + allocAmount) <= totalSupply) {
            teamTranchesReleased++;
            balanceOf[yoobaTeamAddress] = safeAdd(balanceOf[yoobaTeamAddress], allocAmount);
            currentSupply += allocAmount;
            tokensReleasedToTeam = safeAdd(tokensReleasedToTeam, allocAmount);
            Transfer(0x0, yoobaTeamAddress, allocAmount);
            return true;
        }
        revert();
    }

  
    
         
    function releaseForIco(address _icoAddress, uint256 _value) public  ownerOnly stoppable returns(bool success) {
          require(_icoAddress != address(0x0) && _value > 0  && (tokensReleasedToIco + _value) <= icoReservedSupply && (currentSupply + _value) <= totalSupply);
          balanceOf[_icoAddress] = safeAdd(balanceOf[_icoAddress], _value);
          currentSupply += _value;
          tokensReleasedToIco += _value;
          Transfer(0x0, _icoAddress, _value);
         return true;
    }

         
    function releaseForEarlyInvestor(address _investorAddress, uint256 _value) public  ownerOnly  stoppable  returns(bool success) {
          require(_investorAddress != address(0x0) && _value > 0  && (tokensReleasedToEarlyInvestor + _value) <= earlyInvestorSupply && (currentSupply + _value) <= totalSupply);
          balanceOf[_investorAddress] = safeAdd(balanceOf[_investorAddress], _value);
          currentSupply += _value;
          tokensReleasedToEarlyInvestor += _value;
          Transfer(0x0, _investorAddress, _value);
         return true;
    }
     
    function processWhenStop() public  ownerOnly   returns(bool success) {
        require(currentSupply <=  totalSupply && stopped);
        balanceOf[backupAddress] += (totalSupply - currentSupply);
        currentSupply = totalSupply;
       Transfer(0x0, backupAddress, (totalSupply - currentSupply));
        return true;
    }
    

}