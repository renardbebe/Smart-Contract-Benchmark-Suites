 

pragma solidity ^0.4.11;

 
 
 
 
 
 
 
 


 
 
 
 
 
 
 
 


 
 
 
 
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) 
        returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant 
        returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, 
        uint _value);
}


 
 
 
 
 
 
 
 

 
 
 
contract Owned {

     
     
     
    address public owner;
    address public newOwner;

     
     
     
    function Owned() {
        owner = msg.sender;
    }


     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


     
     
     
    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

 
     
     
     
    function acceptOwnership() {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


 
 
 
 
 
 
 
 


 
 
 
library SafeMath {

     
     
     
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


 
 
 
 
 
 
 
 

 
 
 
contract OpenANXTokenConfig {

     
     
     
    string public constant SYMBOL = "OAX";
    string public constant NAME = "openANX Token";
    uint8 public constant DECIMALS = 18;


     
     
     
    uint public constant DECIMALSFACTOR = 10**uint(DECIMALS);

     
     
     
    uint public constant TOKENS_SOFT_CAP = 13000000 * DECIMALSFACTOR;
    uint public constant TOKENS_HARD_CAP = 30000000 * DECIMALSFACTOR;
    uint public constant TOKENS_TOTAL = 100000000 * DECIMALSFACTOR;

     
     
     
     
     
     
    uint public constant START_DATE = 1498136400;
    uint public constant END_DATE = 1500728400;

     
     
     
     
    uint public constant LOCKED_1Y_DATE = START_DATE + 365 days;
    uint public constant LOCKED_2Y_DATE = START_DATE + 2 * 365 days;

     
     
     
     
    uint public CONTRIBUTIONS_MIN = 0 ether;
    uint public CONTRIBUTIONS_MAX = 0 ether;
}


 
 
 
 
 
 
 
 



 
 
 
contract LockedTokens is OpenANXTokenConfig {
    using SafeMath for uint;

     
     
     
     
    uint public constant TOKENS_LOCKED_1Y_TOTAL = 14000000 * DECIMALSFACTOR;
    uint public constant TOKENS_LOCKED_2Y_TOTAL = 26000000 * DECIMALSFACTOR;
    
     
     
     
    address public TRANCHE2_ACCOUNT = 0x813703Eb676f3B6C76dA75cBa0cbC49DdbCA7B37;

     
     
     
    uint public totalSupplyLocked1Y;
    uint public totalSupplyLocked2Y;

     
     
     
    mapping (address => uint) public balancesLocked1Y;
    mapping (address => uint) public balancesLocked2Y;

     
     
     
    ERC20Interface public tokenContract;


     
     
     
    function LockedTokens(address _tokenContract) {
        tokenContract = ERC20Interface(_tokenContract);

         

         
        add1Y(0x4beE088efDBCC610EEEa101ded7204150AF1C8b9,1000000 * DECIMALSFACTOR);
        add1Y(0x839551201f866907Eb5017bE79cEB48aDa58650c,925000 * DECIMALSFACTOR);
        add1Y(0xa92d4Cd3412862386c234Be572Fe4A8FA4BB09c6,925000 * DECIMALSFACTOR);
        add1Y(0xECf2B5fce33007E5669D63de39a4c663e56958dD,925000 * DECIMALSFACTOR);
        add1Y(0xD6B7695bc74E2C950eb953316359Eab283C5Bda8,925000 * DECIMALSFACTOR);
        add1Y(0xBE3463Eae26398D55a7118683079264BcF3ab24B,150000 * DECIMALSFACTOR);
        add1Y(0xf47428Fb9A61c9f3312cB035AEE049FBa76ba62a,150000 * DECIMALSFACTOR);
        add1Y(0xfCcc77165D822Ef9004714d829bDC267C743658a,50000 * DECIMALSFACTOR);
        add1Y(0xaf8df2aCAec3d5d92dE42a6c19d7706A4F3E8D8b,50000 * DECIMALSFACTOR);
        add1Y(0x22a6f9693856374BF2922cd837d07F6670E7FA4d,250000 * DECIMALSFACTOR);
        add1Y(0x3F720Ca8FfF598F00a51DE32A8Cb58Ca73f22aDe,50000 * DECIMALSFACTOR);
        add1Y(0xBd0D1954B301E414F0b5D0827A69EC5dD559e50B,50000 * DECIMALSFACTOR);
        add1Y(0x2ad6B011FEcDE830c9cc4dc0d0b77F055D6b5990,50000 * DECIMALSFACTOR);
        add1Y(0x0c5cD0E971cA18a0F0E0d581f4B93FaD31D608B0,2000085 * DECIMALSFACTOR);
        add1Y(0xFaaDC4d80Eaf430Ab604337CB67d77eC763D3e23,200248 * DECIMALSFACTOR);
        add1Y(0xDAef46f89c264182Cd87Ce93B620B63c7AfB14f7,1616920 * DECIMALSFACTOR);
        add1Y(0x19cc59C30cE54706633dC29EdEbAE1efF1757b25,224980 * DECIMALSFACTOR);
        add1Y(0xa130fE5D399104CA5AF168fbbBBe19F95d739741,745918 * DECIMALSFACTOR);
        add1Y(0xC0cD1bf6F2939095a56B0DFa085Ba2886b84E7d1,745918 * DECIMALSFACTOR);
        add1Y(0xf2C26e79eD264B0E3e5A5DFb1Dd91EA61f512C6e,745918 * DECIMALSFACTOR);
        add1Y(0x5F876a8A5F1B66fbf3D0D119075b62aF4386e319,745918 * DECIMALSFACTOR);
        add1Y(0xb8E046570800Dd76720aF6d42d3cCae451F54f15,745920 * DECIMALSFACTOR);
        add1Y(0xA524fa65Aac4647fa7bA2c20D22F64450c351bBd,714286 * DECIMALSFACTOR);
        add1Y(0x27209b276C15a936BCE08D7D70f0c97aeb3CE8c3,13889 * DECIMALSFACTOR);

        assert(totalSupplyLocked1Y == TOKENS_LOCKED_1Y_TOTAL);

         
        add2Y(0x4beE088efDBCC610EEEa101ded7204150AF1C8b9,1000000 * DECIMALSFACTOR);
        add2Y(0x839551201f866907Eb5017bE79cEB48aDa58650c,925000 * DECIMALSFACTOR);
        add2Y(0xa92d4Cd3412862386c234Be572Fe4A8FA4BB09c6,925000 * DECIMALSFACTOR);
        add2Y(0xECf2B5fce33007E5669D63de39a4c663e56958dD,925000 * DECIMALSFACTOR);
        add2Y(0xD6B7695bc74E2C950eb953316359Eab283C5Bda8,925000 * DECIMALSFACTOR);
        add2Y(0xBE3463Eae26398D55a7118683079264BcF3ab24B,150000 * DECIMALSFACTOR);
        add2Y(0xf47428Fb9A61c9f3312cB035AEE049FBa76ba62a,150000 * DECIMALSFACTOR);
        add2Y(0xfCcc77165D822Ef9004714d829bDC267C743658a,50000 * DECIMALSFACTOR);
        add2Y(0xDAef46f89c264182Cd87Ce93B620B63c7AfB14f7,500000 * DECIMALSFACTOR);
        add2Y(0xaf8df2aCAec3d5d92dE42a6c19d7706A4F3E8D8b,50000 * DECIMALSFACTOR);
        add2Y(0x22a6f9693856374BF2922cd837d07F6670E7FA4d,250000 * DECIMALSFACTOR);
        add2Y(0x3F720Ca8FfF598F00a51DE32A8Cb58Ca73f22aDe,50000 * DECIMALSFACTOR);
        add2Y(0xBd0D1954B301E414F0b5D0827A69EC5dD559e50B,50000 * DECIMALSFACTOR);
        add2Y(0x2ad6B011FEcDE830c9cc4dc0d0b77F055D6b5990,50000 * DECIMALSFACTOR);

         
        add2Y(0x990a2D172398007fcbd5078D84696BdD8cCDf7b2,20000000 * DECIMALSFACTOR);

        assert(totalSupplyLocked2Y == TOKENS_LOCKED_2Y_TOTAL);
    }


     
     
     
    function addRemainingTokens() {
         
        require(msg.sender == address(tokenContract));
         
        uint remainingTokens = TOKENS_TOTAL;
         
        remainingTokens = remainingTokens.sub(tokenContract.totalSupply());
         
        remainingTokens = remainingTokens.sub(totalSupplyLocked1Y);
         
        remainingTokens = remainingTokens.sub(totalSupplyLocked2Y);
         
        add1Y(TRANCHE2_ACCOUNT, remainingTokens);
    }


     
     
     
    function add1Y(address account, uint value) private {
        balancesLocked1Y[account] = balancesLocked1Y[account].add(value);
        totalSupplyLocked1Y = totalSupplyLocked1Y.add(value);
    }


     
     
     
    function add2Y(address account, uint value) private {
        balancesLocked2Y[account] = balancesLocked2Y[account].add(value);
        totalSupplyLocked2Y = totalSupplyLocked2Y.add(value);
    }


     
     
     
    function balanceOfLocked1Y(address account) constant returns (uint balance) {
        return balancesLocked1Y[account];
    }


     
     
     
    function balanceOfLocked2Y(address account) constant returns (uint balance) {
        return balancesLocked2Y[account];
    }


     
     
     
    function balanceOfLocked(address account) constant returns (uint balance) {
        return balancesLocked1Y[account].add(balancesLocked2Y[account]);
    }


     
     
     
    function totalSupplyLocked() constant returns (uint) {
        return totalSupplyLocked1Y + totalSupplyLocked2Y;
    }


     
     
     
    function unlock1Y() {
        require(now >= LOCKED_1Y_DATE);
        uint amount = balancesLocked1Y[msg.sender];
        require(amount > 0);
        balancesLocked1Y[msg.sender] = 0;
        totalSupplyLocked1Y = totalSupplyLocked1Y.sub(amount);
        if (!tokenContract.transfer(msg.sender, amount)) throw;
    }


     
     
     
    function unlock2Y() {
        require(now >= LOCKED_2Y_DATE);
        uint amount = balancesLocked2Y[msg.sender];
        require(amount > 0);
        balancesLocked2Y[msg.sender] = 0;
        totalSupplyLocked2Y = totalSupplyLocked2Y.sub(amount);
        if (!tokenContract.transfer(msg.sender, amount)) throw;
    }
}



 
 
 
contract ERC20Token is ERC20Interface, Owned {
    using SafeMath for uint;

     
     
     
    string public symbol;
    string public name;
    uint8 public decimals;

     
     
     
    mapping(address => uint) balances;

     
     
     
    mapping(address => mapping (address => uint)) allowed;


     
     
     
    function ERC20Token(
        string _symbol, 
        string _name, 
        uint8 _decimals, 
        uint _totalSupply
    ) Owned() {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[owner] = _totalSupply;
    }


     
     
     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }


     
     
     
    function transfer(address _to, uint _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount              
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


     
     
     
     
     
    function approve(
        address _spender,
        uint _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


     
     
     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}


 
 
 
contract OpenANXToken is ERC20Token, OpenANXTokenConfig {

     
     
     
    bool public finalised = false;

     
     
     
     
     
     
     
     
     
     
     
     
    uint public tokensPerKEther = 343734;

     
     
     
    LockedTokens public lockedTokens;

     
     
     
    address public wallet;

     
     
     
     
    mapping(address => bool) public kycRequired;


     
     
     
    function OpenANXToken(address _wallet) 
        ERC20Token(SYMBOL, NAME, DECIMALS, 0)
    {
        wallet = _wallet;
        lockedTokens = new LockedTokens(this);
        require(address(lockedTokens) != 0x0);
    }

     
     
     
     
     
     
    function setWallet(address _wallet) onlyOwner {
        wallet = _wallet;
        WalletUpdated(wallet);
    }
    event WalletUpdated(address newWallet);


     
     
     
     
    function setTokensPerKEther(uint _tokensPerKEther) onlyOwner {
        require(now < START_DATE);
        require(_tokensPerKEther > 0);
        tokensPerKEther = _tokensPerKEther;
        TokensPerKEtherUpdated(tokensPerKEther);
    }
    event TokensPerKEtherUpdated(uint tokensPerKEther);


     
     
     
    function () payable {
        proxyPayment(msg.sender);
    }


     
     
     
     
     
    function proxyPayment(address participant) payable {
         
        require(!finalised);

         
        require(now >= START_DATE);
         
        require(now <= END_DATE);

         
        require(msg.value >= CONTRIBUTIONS_MIN);
         
        require(CONTRIBUTIONS_MAX == 0 || msg.value < CONTRIBUTIONS_MAX);

         
         
         
         
        uint tokens = msg.value * tokensPerKEther / 10**uint(18 - decimals + 3);

         
        require(totalSupply + tokens <= TOKENS_HARD_CAP);

         
        balances[participant] = balances[participant].add(tokens);
        totalSupply = totalSupply.add(tokens);

         
        Transfer(0x0, participant, tokens);
        TokensBought(participant, msg.value, this.balance, tokens,
             totalSupply, tokensPerKEther);

         
        kycRequired[participant] = true;

         
        if (!wallet.send(msg.value)) throw;
    }
    event TokensBought(address indexed buyer, uint ethers, 
        uint newEtherBalance, uint tokens, uint newTotalSupply, 
        uint tokensPerKEther);


     
     
     
     
    function finalise() onlyOwner {
         
        require(totalSupply >= TOKENS_SOFT_CAP || now > END_DATE);

         
        require(!finalised);

         
        lockedTokens.addRemainingTokens();

         
        balances[address(lockedTokens)] = balances[address(lockedTokens)].
            add(lockedTokens.totalSupplyLocked());
        totalSupply = totalSupply.add(lockedTokens.totalSupplyLocked());

         
        finalised = true;
    }


     
     
     
     
    function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now < START_DATE);
        require(balance > 0);
        balances[participant] = balances[participant].add(balance);
        totalSupply = totalSupply.add(balance);
        Transfer(0x0, participant, balance);
    }
    event PrecommitmentAdded(address indexed participant, uint balance);


     
     
     
     
    function transfer(address _to, uint _amount) returns (bool success) {
         
        require(finalised);
         
        require(!kycRequired[msg.sender]);
         
        return super.transfer(_to, _amount);
    }


     
     
     
     
     
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
         
        require(finalised);
         
        require(!kycRequired[_from]);
         
        return super.transferFrom(_from, _to, _amount);
    }


     
     
     
    function kycVerify(address participant) onlyOwner {
        kycRequired[participant] = false;
        KycVerified(participant);
    }
    event KycVerified(address indexed participant);


     
     
     
     
     
    function burnFrom(
        address _from,
        uint _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][0x0] >= _amount            
            && _amount > 0                               
            && balances[0x0] + _amount > balances[0x0]   
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][0x0] = allowed[_from][0x0].sub(_amount);
            balances[0x0] = balances[0x0].add(_amount);
            totalSupply = totalSupply.sub(_amount);
            Transfer(_from, 0x0, _amount);
            return true;
        } else {
            return false;
        }
    }


     
     
     
    function balanceOfLocked1Y(address account) constant returns (uint balance) {
        return lockedTokens.balanceOfLocked1Y(account);
    }


     
     
     
    function balanceOfLocked2Y(address account) constant returns (uint balance) {
        return lockedTokens.balanceOfLocked2Y(account);
    }


     
     
     
    function balanceOfLocked(address account) constant returns (uint balance) {
        return lockedTokens.balanceOfLocked(account);
    }


     
     
     
    function totalSupplyLocked1Y() constant returns (uint) {
        if (finalised) {
            return lockedTokens.totalSupplyLocked1Y();
        } else {
            return 0;
        }
    }


     
     
     
    function totalSupplyLocked2Y() constant returns (uint) {
        if (finalised) {
            return lockedTokens.totalSupplyLocked2Y();
        } else {
            return 0;
        }
    }


     
     
     
    function totalSupplyLocked() constant returns (uint) {
        if (finalised) {
            return lockedTokens.totalSupplyLocked();
        } else {
            return 0;
        }
    }


     
     
     
    function totalSupplyUnlocked() constant returns (uint) {
        if (finalised && totalSupply >= lockedTokens.totalSupplyLocked()) {
            return totalSupply.sub(lockedTokens.totalSupplyLocked());
        } else {
            return 0;
        }
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }
}