 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
contract DeveryPresaleWhitelist {
    mapping(address => uint) public whitelist;
}


 
 
 
contract PICOPSCertifier {
    function certified(address) public constant returns (bool);
}


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
 
contract ERC20Token is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    bool public transferable;
    bool public mintable = true;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event MintingDisabled();
    event TransfersEnabled();

    function ERC20Token(string _symbol, string _name, uint8 _decimals) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
    }

     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        require(transferable);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        require(transferable);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(transferable);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
    function disableMinting() internal {
        require(mintable);
        mintable = false;
        MintingDisabled();
    }
    function enableTransfers() public onlyOwner {
        require(!transferable);
        transferable = true;
        TransfersEnabled();
    }
    function mint(address tokenOwner, uint tokens) internal {
        require(mintable);
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        Transfer(address(0), tokenOwner, tokens);
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


 
 
 
contract DeveryPresale is ERC20Token {
    address public wallet;
     
    uint public constant START_DATE = 1513267028;
    bool public closed;
    uint public ethMinContribution = 0.01 ether;
    uint public constant TEST_CONTRIBUTION = 0.01 ether;
    uint public usdCap = 2000000;
     
    uint public usdPerKEther = 730000;
    uint public contributedEth;
    uint public contributedUsd;
    DeveryPresaleWhitelist public whitelist = DeveryPresaleWhitelist(0xB74c2851d55CD01A43BDD0878fe6C0FF984A8203);
    PICOPSCertifier public picopsCertifier = PICOPSCertifier(0x1e2F058C43ac8965938F6e9CA286685A3E63F24E);

    event WalletUpdated(address indexed oldWallet, address indexed newWallet);
    event EthMinContributionUpdated(uint oldEthMinContribution, uint newEthMinContribution);
    event UsdCapUpdated(uint oldUsdCap, uint newUsdCap);
    event UsdPerKEtherUpdated(uint oldUsdPerKEther, uint newUsdPerKEther);
    event WhitelistUpdated(address indexed oldWhitelist, address indexed newWhitelist);
    event PICOPSCertifierUpdated(address indexed oldPICOPSCertifier, address indexed newPICOPSCertifier);
    event Contributed(address indexed addr, uint ethAmount, uint ethRefund, uint usdAmount, uint contributedEth, uint contributedUsd);

    function DeveryPresale() public ERC20Token("Zqir6DBAX9VV", "Zqir6DBAX9VV", 18) {
        wallet = owner;
    }
    function setWallet(address _wallet) public onlyOwner {
         
        WalletUpdated(wallet, _wallet);
        wallet = _wallet;
    } 
    function setEthMinContribution(uint _ethMinContribution) public onlyOwner {
         
        EthMinContributionUpdated(ethMinContribution, _ethMinContribution);
        ethMinContribution = _ethMinContribution;
    } 
    function setUsdCap(uint _usdCap) public onlyOwner {
         
        UsdCapUpdated(usdCap, _usdCap);
        usdCap = _usdCap;
    } 
    function setUsdPerKEther(uint _usdPerKEther) public onlyOwner {
         
        UsdPerKEtherUpdated(usdPerKEther, _usdPerKEther);
        usdPerKEther = _usdPerKEther;
    }
    function setWhitelist(address _whitelist) public onlyOwner {
         
        WhitelistUpdated(address(whitelist), _whitelist);
        whitelist = DeveryPresaleWhitelist(_whitelist);
    }
    function setPICOPSCertifier(address _picopsCertifier) public onlyOwner {
         
        PICOPSCertifierUpdated(address(picopsCertifier), _picopsCertifier);
        picopsCertifier = PICOPSCertifier(_picopsCertifier);
    }
    function addressCanContribute(address _addr) public view returns (bool) {
        return whitelist.whitelist(_addr) > 0 || picopsCertifier.certified(_addr);
    }
    function ethCap() public view returns (uint) {
        return usdCap * 10**uint(3 + 18) / usdPerKEther;
    }
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
        disableMinting();
    }
    function () public payable {
        require(now >= START_DATE || (msg.sender == owner && msg.value == TEST_CONTRIBUTION));
        require(!closed);
        require(addressCanContribute(msg.sender));
        require(msg.value >= ethMinContribution || (msg.sender == owner && msg.value == TEST_CONTRIBUTION));
        uint ethAmount = msg.value;
        uint ethRefund = 0;
        if (contributedEth.add(ethAmount) > ethCap()) {
            ethAmount = ethCap().sub(contributedEth);
            ethRefund = msg.value.sub(ethAmount);
        }
        require(ethAmount > 0);
        uint usdAmount = ethAmount * usdPerKEther / 10**uint(3 + 18);
        contributedEth = contributedEth.add(ethAmount);
        contributedUsd = contributedUsd.add(usdAmount);
        mint(msg.sender, ethAmount);
        wallet.transfer(ethAmount);
        Contributed(msg.sender, ethAmount, ethRefund, usdAmount, contributedEth, contributedUsd);
        if (ethRefund > 0) {
            msg.sender.transfer(ethRefund);
        }
    }
}