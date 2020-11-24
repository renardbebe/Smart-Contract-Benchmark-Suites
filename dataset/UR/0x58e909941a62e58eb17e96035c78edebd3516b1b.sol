 


contract SlrsToken is ERC20Interface, Ownable {

    using SafeMath for uint256;
    uint256  public  totalSupply;
    address public itoContract;

    mapping  (address => uint256)             public          _balances;
    mapping  (address => mapping (address => uint256)) public  _approvals;


    string   public  name = "SolarStake Token";
    string   public  symbol = "SLRS";
    uint256  public  decimals = 18;

    event Mint(uint256 tokens);
    event MintToWallet(address indexed to, uint256 tokens);
    event MintFromContract(address indexed to, uint256 tokens);
    event Burn(uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor () public{
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return _balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return _approvals[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens > 0 && _balances[msg.sender] >= tokens);
        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(tokens > 0 && _balances[from] >= tokens && _approvals[from][msg.sender] >= tokens);
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(tokens);
        _balances[from] = _balances[from].sub(tokens);
        _balances[to] = _balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        require(spender != address(0));
        require(tokens > 0 && tokens <= _balances[msg.sender]);
        _approvals[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
    function mint(uint256 tokens) public onlyOwner returns (bool) {
        require(tokens > 0);
        _balances[msg.sender] = _balances[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        emit Mint(tokens);
        return true;
    }

     
    function mintToWallet(address to, uint256 tokens) public onlyOwner returns (bool) {
      totalSupply = totalSupply.add(tokens);
      _balances[to] = _balances[to].add(tokens);
      emit MintToWallet(to, tokens);
      return true;
    }

     
    function mintFromContract(address to, uint256 tokens) public returns (bool) {
      require(msg.sender == itoContract);
      totalSupply = totalSupply.add(tokens);
      _balances[to] = _balances[to].add(tokens);
      emit MintFromContract(to, tokens);
      return true;
    }

     
    function burn(uint256 tokens) public onlyOwner returns (bool)  {
        require(tokens > 0 && tokens <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        emit Burn(tokens);
        return true;
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
    function setItoContract(address _itoContract) public onlyOwner {
      if (_itoContract != address(0)) {
        itoContract = _itoContract;
      }
    }

}
