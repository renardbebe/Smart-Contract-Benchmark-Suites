 

 


pragma solidity ^0.4.11;

contract owned {

    address public owner;
    address public candidate;

    function owned() payable public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }

    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

contract CryptaurToken is owned {

    address                      public cryptaurBackend;
    bool                         public crowdsaleFinished;
    uint                         public totalSupply;
    mapping (address => uint256) public balanceOf;

    string  public standard    = 'Token 0.1';
    string  public name        = 'Cryptaur';
    string  public symbol      = "CPT";
    uint8   public decimals    = 8;

    mapping (address => mapping (address => uint)) public allowed;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Mint(address indexed minter, uint tokens, uint8 originalCoinType, bytes32 originalTxHash);

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function CryptaurToken(address _cryptaurBackend) public payable owned() {
        cryptaurBackend = _cryptaurBackend;
    }

    function changeBackend(address _cryptaurBackend) public onlyOwner {
        cryptaurBackend = _cryptaurBackend;
    }

    function mintTokens(address _minter, uint _tokens, uint8 _originalCoinType, bytes32 _originalTxHash) public {
        require(msg.sender == cryptaurBackend);
        require(!crowdsaleFinished);
        balanceOf[_minter] += _tokens;
        totalSupply += _tokens;
        Transfer(this, _minter, _tokens);
        Mint(_minter, _tokens, _originalCoinType, _originalTxHash);
    }

    function finishCrowdsale() onlyOwner public {
        crowdsaleFinished = true;
    }

    function transfer(address _to, uint256 _value)
        public onlyPayloadSize(2 * 32) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        public onlyPayloadSize(3 * 32) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        require(allowed[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant
        returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}