 

 
pragma solidity ^0.4.11;


 
 

 
library SMathLib {

    function times(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a);
        return c;
    }

}

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

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
 



 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



 



 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract StandardToken is ERC20, SafeMath {

     
    event Minted(address receiver, uint amount);

     
    mapping(address => uint) balances;

     
    mapping (address => mapping (address => uint)) allowed;

     
    function isToken() public constant returns (bool weAre) {
        return true;
    }

    function transfer(address _to, uint _value) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        uint _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {

         
         
         
         
        require ((_value != 0) && (allowed[msg.sender][_spender] != 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

 





 



 
contract UpgradeAgent {

    uint public originalSupply;

     
    function isUpgradeAgent() public constant returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is StandardToken {

     
    address public upgradeMaster;

     
    UpgradeAgent public upgradeAgent;

     
    uint256 public totalUpgraded;

     
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event UpgradeAgentSet(address agent);

     
    function UpgradeableToken(address _upgradeMaster) {
        upgradeMaster = _upgradeMaster;
    }

     
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        require(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));

         
        require (value == 0);

        balances[msg.sender] = safeSub(balances[msg.sender], value);

         
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);

         
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
    function setUpgradeAgent(address agent) external {

        require(!canUpgrade());  

        require(agent == 0x0);
         
        require(msg.sender != upgradeMaster);
         
        require(getUpgradeState() == UpgradeState.Upgrading);

        upgradeAgent = UpgradeAgent(agent);

         
        require(!upgradeAgent.isUpgradeAgent());
         
        require(upgradeAgent.originalSupply() != totalSupply);

        UpgradeAgentSet(upgradeAgent);
    }

     
    function getUpgradeState() public constant returns(UpgradeState) {
        if(!canUpgrade()) return UpgradeState.NotAllowed;
        else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function setUpgradeMaster(address master) public {
        require(master == 0x0);
        require(msg.sender != upgradeMaster);
        upgradeMaster = master;
    }

     
    function canUpgrade() public constant returns(bool) {
        return true;
    }

}

 




 
contract MintableTokenExt is StandardToken, Ownable {

    using SMathLib for uint;

    bool public mintingFinished = false;

     
    mapping (address => bool) public mintAgents;

    event MintingAgentChanged(address addr, bool state  );

     
    struct ReservedTokensData {
        uint inTokens;
        uint inPercentageUnit;
        uint inPercentageDecimals;
    }

    mapping (address => ReservedTokensData) public reservedTokensList;
    address[] public reservedTokensDestinations;
    uint public reservedTokensDestinationsLen = 0;

    function setReservedTokensList(address addr, uint inTokens, uint inPercentageUnit, uint inPercentageDecimals) onlyOwner {
        reservedTokensDestinations.push(addr);
        reservedTokensDestinationsLen++;
        reservedTokensList[addr] = ReservedTokensData({inTokens:inTokens, inPercentageUnit:inPercentageUnit, inPercentageDecimals: inPercentageDecimals});
    }

    function getReservedTokensListValInTokens(address addr) constant returns (uint inTokens) {
        return reservedTokensList[addr].inTokens;
    }

    function getReservedTokensListValInPercentageUnit(address addr) constant returns (uint inPercentageUnit) {
        return reservedTokensList[addr].inPercentageUnit;
    }

    function getReservedTokensListValInPercentageDecimals(address addr) constant returns (uint inPercentageDecimals) {
        return reservedTokensList[addr].inPercentageDecimals;
    }

    function setReservedTokensListMultiple(address[] addrs, uint[] inTokens, uint[] inPercentageUnit, uint[] inPercentageDecimals) onlyOwner {
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            setReservedTokensList(addrs[iterator], inTokens[iterator], inPercentageUnit[iterator], inPercentageDecimals[iterator]);
        }
    }

     
    function mint(address receiver, uint amount) onlyMintAgent canMint public {
        totalSupply = totalSupply.plus(amount);
        balances[receiver] = balances[receiver].plus(amount);

         
         
        Transfer(0, receiver, amount);
    }

     
    function setMintAgent(address addr, bool state) onlyOwner canMint public {
        mintAgents[addr] = state;
        MintingAgentChanged(addr, state);
    }

    modifier onlyMintAgent() {
         
        if(!mintAgents[msg.sender]) {
            revert();
        }
        _;
    }

     
    modifier canMint() {
        if(mintingFinished) {
            revert();
        }
        _;
    }
}
 



 
contract ReleasableToken is ERC20, Ownable {

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping (address => bool) public transferAgents;

     
    modifier canTransfer(address _sender) {

        if(!released) {
            if(!transferAgents[_sender]) {
                revert();
            }
        }

        _;
    }

     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

         
        releaseAgent = addr;
    }

     
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        transferAgents[addr] = state;
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

     
    modifier inReleaseState(bool releaseState) {
        if(releaseState != released) {
            revert();
        }
        _;
    }

     
    modifier onlyReleaseAgent() {
        if(msg.sender != releaseAgent) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
         
        return super.transferFrom(_from, _to, _value);
    }

}

 






contract BurnableToken is StandardToken {

    using SMathLib for uint;
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].minus(_value);
        totalSupply = totalSupply.minus(_value);
        Burn(burner, _value);
    }
}




 
contract CrowdsaleTokenExt is ReleasableToken, MintableTokenExt, BurnableToken, UpgradeableToken {

     
    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;

    string public symbol;

    uint public decimals;

     
    uint public minCap;


     
    function CrowdsaleTokenExt(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap)
    UpgradeableToken(msg.sender) {

         
         
         
        owner = msg.sender;

        name = _name;
        symbol = _symbol;

        totalSupply = _initialSupply;

        decimals = _decimals;

        minCap = _globalMinCap;

         
        balances[owner] = totalSupply;

        if(totalSupply > 0) {
            Minted(owner, totalSupply);
        }

         
        if(!_mintable) {
            mintingFinished = true;
            if(totalSupply == 0) {
                revert();  
            }
        }
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        super.releaseTokenTransfer();
    }

     
    function canUpgrade() public constant returns(bool) {
        return released && super.canUpgrade();
    }

     
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        name = _name;
        symbol = _symbol;

        UpdatedTokenInformation(name, symbol);
    }

}


contract MjtToken is CrowdsaleTokenExt {

    uint public ownersProductCommissionInPerc = 5;

    uint public operatorProductCommissionInPerc = 25;

    event IndependentSellerJoined(address sellerWallet, uint amountOfTokens, address operatorWallet);
    event OwnersProductAdded(address ownersWallet, uint amountOfTokens, address operatorWallet);
    event OperatorProductCommissionChanged(uint _value);
    event OwnersProductCommissionChanged(uint _value);


    function setOperatorCommission(uint _value) public onlyOwner {
        require(_value >= 0);
        operatorProductCommissionInPerc = _value;
        OperatorProductCommissionChanged(_value);
    }

    function setOwnersCommission(uint _value) public onlyOwner {
        require(_value >= 0);
        ownersProductCommissionInPerc = _value;
        OwnersProductCommissionChanged(_value);
    }


     
    function independentSellerJoined(address sellerWallet, uint amountOfTokens, address operatorWallet) public onlyOwner canMint {
        require(amountOfTokens > 100);
        require(sellerWallet != address(0));
        require(operatorWallet != address(0));

        uint operatorCommission = amountOfTokens.divides(100).times(operatorProductCommissionInPerc);
        uint sellerAmount = amountOfTokens.minus(operatorCommission);

        if (operatorCommission > 0) {
            mint(operatorWallet, operatorCommission);
        }

        if (sellerAmount > 0) {
            mint(sellerWallet, sellerAmount);
        }
        IndependentSellerJoined(sellerWallet, amountOfTokens, operatorWallet);
    }


     
    function ownersProductAdded(address ownersWallet, uint amountOfTokens, address operatorWallet) public onlyOwner canMint {
        require(amountOfTokens > 100);
        require(ownersWallet != address(0));
        require(operatorWallet != address(0));

        uint ownersComission = amountOfTokens.divides(100).times(ownersProductCommissionInPerc);
        uint operatorAmount = amountOfTokens.minus(ownersComission);


        if (ownersComission > 0) {
            mint(ownersWallet, ownersComission);
        }

        if (operatorAmount > 0) {
            mint(operatorWallet, operatorAmount);
        }

        OwnersProductAdded(ownersWallet, amountOfTokens, operatorWallet);
    }

    function MjtToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap)
    CrowdsaleTokenExt(_name, _symbol, _initialSupply, _decimals, _mintable, _globalMinCap) {}

}