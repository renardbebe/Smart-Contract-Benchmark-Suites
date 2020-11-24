 

contract SafeMath {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract Lockable is Owned {

    uint256 public lockedUntilBlock;

    event ContractLocked(uint256 _untilBlock, string _reason);

    modifier lockAffected {
        require(block.number > lockedUntilBlock);
        _;
    }

    function lockFromSelf(uint256 _untilBlock, string _reason) internal {
        lockedUntilBlock = _untilBlock;
        ContractLocked(_untilBlock, _reason);
    }


    function lockUntil(uint256 _untilBlock, string _reason) onlyOwner public {
        lockedUntilBlock = _untilBlock;
        ContractLocked(_untilBlock, _reason);
    }
}

contract ERC20TokenInterface {
  function totalSupply() public constant returns (uint256 _totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract ERC20PrivateInterface {
    uint256 supply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract tokenRecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}
contract OwnedInterface {
    address public owner;
    address public newOwner;

    modifier onlyOwner {
        _;
    }
}

contract ERC20Token is ERC20TokenInterface, SafeMath, Owned, Lockable {

     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;
     
    address public mintingContract;

     
    uint256 supply = 0;
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowances;

     
    event Mint(address indexed _to, uint256 _value);
     
    event Burn(address indexed _from, uint _value);

     
    function totalSupply() public constant returns (uint256) {
        return supply;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) lockAffected public returns (bool success) {
        require(_to != 0x0 && _to != address(this));
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) lockAffected public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) lockAffected public returns (bool success) {
        tokenRecipientInterface spender = tokenRecipientInterface(_spender);
        approve(_spender, _value);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) lockAffected public returns (bool success) {
        require(_to != 0x0 && _to != address(this));
        balances[_from] = safeSub(balanceOf(_from), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

     
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == mintingContract);
        supply = safeAdd(supply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Mint(_to, _amount);
        emit Transfer(0x0, _to, _amount);
    }

     
    function burn(uint _amount) public {
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _amount);
        supply = safeSub(supply, _amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, 0x0, _amount);
    }

     
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }

     
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}







contract MintableTokenInterface {
    function mint(address _to, uint256 _amount) public;
}


contract MintingContract is Owned, SafeMath{
    
    address public tokenAddress;
    uint256 public tokensAlreadyMinted;

    enum state { crowdsaleMinting, teamMinting, finished}
    state public mintingState; 

    address public crowdsaleContractAddress;
    uint256 public crowdsaleMintingCap;

    uint256 public teamTokensCap;
    address public teamTokenAddress;

    uint256 public communityTokensCap;
    address public communityAddress;
    uint256 public comunityMintedTokens;
    
    function MintingContract() public {
        tokensAlreadyMinted = 0;
        crowdsaleMintingCap = 200000000 * 10**18;
        teamTokensCap = 45000000 * 10**18;
        teamTokenAddress = 0x0;
        communityTokensCap = 5000000 * 10**18;
        communityAddress = 0x0;

    }
    
    function doCommunityMinting(address _destination, uint _tokensToMint) public {
        require(msg.sender == communityAddress || msg.sender == owner);
        require(safeAdd(comunityMintedTokens, _tokensToMint) <= communityTokensCap);

        MintableTokenInterface(tokenAddress).mint(_destination, _tokensToMint);
        comunityMintedTokens = safeAdd(comunityMintedTokens, _tokensToMint);
    }

    function doPresaleMinting(address _destination, uint _tokensToMint) public onlyOwner {
        require(mintingState == state.crowdsaleMinting);
        require(safeAdd(tokensAlreadyMinted, _tokensToMint) <= crowdsaleMintingCap);

        MintableTokenInterface(tokenAddress).mint(_destination, _tokensToMint);
        tokensAlreadyMinted = safeAdd(tokensAlreadyMinted, _tokensToMint);
    }
    function doCrowdsaleMinting(address _destination, uint _tokensToMint) public {
        require(msg.sender == crowdsaleContractAddress);
        require(mintingState == state.crowdsaleMinting);
        require(safeAdd(tokensAlreadyMinted, _tokensToMint) <= crowdsaleMintingCap);

        MintableTokenInterface(tokenAddress).mint(_destination, _tokensToMint);
        tokensAlreadyMinted = safeAdd(tokensAlreadyMinted, _tokensToMint);
    }
    
    function finishCrowdsaleMinting() onlyOwner public {
        mintingState = state.teamMinting;
    }
    
    function doTeamMinting() public {
        require(mintingState == state.teamMinting);
        MintableTokenInterface(tokenAddress).mint(teamTokenAddress, safeSub(crowdsaleMintingCap, tokensAlreadyMinted));
        MintableTokenInterface(tokenAddress).mint(teamTokenAddress, teamTokensCap);
        mintingState = state.finished;
    }

    function setTokenAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }

    function setCrowdsaleContractAddress(address _crowdsaleContractAddress) onlyOwner public {
        crowdsaleContractAddress = _crowdsaleContractAddress;
    }
    
    function setTeamTokenAddress(address _address) onlyOwner public {
        teamTokenAddress = _address;
    }
    
    function setCommunityAddress(address _address) onlyOwner public {
        communityAddress = _address;
    }
}