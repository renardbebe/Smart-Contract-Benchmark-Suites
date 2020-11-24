 

 

pragma solidity >=0.4.21 <0.6.0;

contract MultiSig{

  struct invoke_status{
    uint propose_height;
    bytes32 invoke_hash;
    string func_name;
    uint64 invoke_id;
    bool called;
    address[] invoke_signers;
    bool processing;
    bool exists;
  }

  uint public signer_number;
  address[] public signers;
  address public owner;
  mapping (bytes32 => invoke_status) public invokes;
  mapping (bytes32 => uint64) public used_invoke_ids;
  mapping(address => uint) public signer_join_height;

  event signers_reformed(address[] old_signers, address[] new_signers);
  event valid_function_sign(string name, uint64 id, uint64 current_signed_number, uint propose_height);
  event function_called(string name, uint64 id, uint propose_height);

  modifier enough_signers(address[] memory s){
    require(s.length >=3, "the number of signers must be >=3");
    _;
  }
  constructor(address[] memory s) public enough_signers(s){
    signers = s;
    signer_number = s.length;
    owner = msg.sender;
    for(uint i = 0; i < s.length; i++){
      signer_join_height[s[i]] = block.number;
    }
  }

  modifier only_signer{
    require(array_exist(signers, msg.sender), "only a signer can call this");
    _;
  }

  function get_majority_number() private view returns(uint){
    return signer_number/2 + 1;
  }

  function array_exist (address[] memory accounts, address p) private pure returns (bool){
    for (uint i = 0; i< accounts.length;i++){
      if (accounts[i]==p){
        return true;
      }
    }
    return false;
  }

  function is_all_minus_sig(uint number, uint64 id, string memory name, bytes32 hash, address sender) internal only_signer returns (bool){
    bytes32 b = keccak256(abi.encodePacked(name));
    require(id <= used_invoke_ids[b] + 1, "you're using a too big id.");

    if(id > used_invoke_ids[b]){
      used_invoke_ids[b] = id;
    }

    if(!invokes[hash].exists){
      invokes[hash].propose_height = block.number;
      invokes[hash].invoke_hash = hash;
      invokes[hash].func_name= name;
      invokes[hash].invoke_id= id;
      invokes[hash].called= false;
      invokes[hash].invoke_signers.push(sender);
      invokes[hash].processing= false;
      invokes[hash].exists= true;
      emit valid_function_sign(name, id, 1, block.number);
      return false;
    }

    invoke_status storage invoke = invokes[hash];
    require(!array_exist(invoke.invoke_signers, sender), "you already called this method");

    uint valid_invoke_num = 0;
    uint join_height = signer_join_height[msg.sender];
    for(uint i = 0; i < invoke.invoke_signers.length; i++){
      require(join_height < invoke.propose_height, "this proposal is already exist before you become a signer");
      if(array_exist(signers, invoke.invoke_signers[i])){
        valid_invoke_num ++;
      }
    }
    invoke.invoke_signers.push(msg.sender);
    valid_invoke_num ++;
    emit valid_function_sign(name, id, uint64(valid_invoke_num), invoke.propose_height);
    if(invoke.called) return false;
    if(valid_invoke_num < signer_number-number) return false;
    invoke.processing = true;
    return true;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(get_majority_number()-1, id, name, hash, msg.sender))
      return ;
    set_called(hash);
    _;
  }

  modifier is_all_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(0, id, name, hash, msg.sender)) return ;
    set_called(hash);
    _;
  }

  function set_called(bytes32 hash) internal only_signer{
    invoke_status storage invoke = invokes[hash];
    require(invoke.exists, "no such function");
    require(!invoke.called, "already called");
    require(invoke.processing, "cannot call this separately");
    invoke.called = true;
    invoke.processing = false;
    emit function_called(invoke.func_name, invoke.invoke_id, invoke.propose_height);
  }

  function reform_signers(uint64 id, address[] calldata s)
    external
    only_signer
    enough_signers(s)
    is_majority_sig(id, "reform_signers"){
    address[] memory old_signers = signers;
    for(uint i = 0; i < s.length; i++){
      if(array_exist(old_signers, s[i])){
      }else{
        signer_join_height[s[i]] = block.number;
      }
    }
    for(uint i = 0; i < old_signers.length; i++){
      if(array_exist(s, old_signers[i])){
      }else{
        signer_join_height[old_signers[i]] = 0;
      }
    }
    signer_number = s.length;
    signers = s;
    emit signers_reformed(old_signers, signers);
  }

  function get_unused_invoke_id(string memory name) public view returns(uint64){
    return used_invoke_ids[keccak256(abi.encodePacked(name))] + 1;
  }
  function get_signers() public view returns(address[] memory){
    return signers;
  }
}

 
 
 
 
 
 
 
 
 

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
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


contract ResearchDAOShare is ERC20Interface, Owned, SafeMath, MultiSig {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public last_block_num;
    uint public period_block_num;
    uint public period_share;
    uint public total_alloc_share;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    mapping(address => uint) public share_amounts;
    address[] shareholders;

    event IssueShare(address account, uint amount);


    constructor(uint start_block_num, uint period, uint share_per_period, address[] memory s) MultiSig(s) public {
        symbol = "RDS";
        name = "ResearchDAOShare";
        decimals = 3;
        _totalSupply = 0;
        last_block_num = start_block_num;
        balances[owner] = _totalSupply;
        period_block_num = period;
        period_share = share_per_period;

        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function issue() public {
      uint interval = safeSub(block.number, last_block_num);
      uint periods = safeDiv(interval, period_block_num);
      if(periods == 0) return ;

      last_block_num = safeAdd(last_block_num, safeMul(periods, period_block_num));
      uint total_allocation = get_total_allocation();
      uint total_shares = safeMul(periods, period_share);
      for(uint i = 0; i < shareholders.length; i++){
        if(share_amounts[shareholders[i]] == 0) continue;
        uint t = safeDiv(safeMul(share_amounts[shareholders[i]], total_shares), total_allocation);
        balances[shareholders[i]] = safeAdd(balances[shareholders[i]], t);
        _totalSupply = safeAdd(_totalSupply, t);
        emit IssueShare(shareholders[i], t);
      }
    }

    function shareholder_exists(address account) private view returns(bool){
        bool exists = false;
        for(uint i = 0; i < shareholders.length; i++){
          if(shareholders[i] == account){
            exists = true;
            break;
          }
        }
        return exists;
    }

    function add_shareholder(uint64 id, address account, uint amount)
      external
      only_signer
      is_majority_sig(id, "add_shareholder")
    {
      require(amount > 0);
      require(account != address(0));
      require(!shareholder_exists(account));

      issue();

      shareholders.push(account);
      share_amounts[account] = amount;
      total_alloc_share = safeAdd(total_alloc_share, amount);
    }

    function config_shareholder(uint64 id, address account, uint amount)
      external
      only_signer
      is_majority_sig(id, "config_shareholder")
    {
        require(account != address(0));
        require(amount > 0);
        require(shareholder_exists(account));

        issue();

        total_alloc_share = safeSub(total_alloc_share, share_amounts[account]);
        total_alloc_share = safeAdd(total_alloc_share, amount);
        share_amounts[account] = amount;
    }

    function add_shareholders(uint64 id, address[] calldata accounts, uint[] calldata amounts)
      external
      only_signer
      is_majority_sig(id, "add_shareholders")
    {
      require(accounts.length == amounts.length);
      require(accounts.length != 0);

      issue();

      for(uint i = 0; i < accounts.length; i++){
        if(accounts[i] == address(0)){continue;}
        if(amounts[i] <=0) continue;
        if(shareholder_exists(accounts[i])){continue;}

        shareholders.push(accounts[i]);
        share_amounts[accounts[i]] = amounts[i];
        total_alloc_share = safeAdd(total_alloc_share, amounts[i]);
      }
    }

    function get_total_allocation() public view returns(uint total){
      return total_alloc_share;
    }

    function get_self_share() public view returns(uint){
      return share_amounts[msg.sender];
    }

    function set_issue_period_param(uint64 id, uint block_num, uint share)
      external
      only_signer
      is_majority_sig(id, "set_issue_period_param")
    {
      require(block_num > 0);
      require(share > 0);
      issue();
      period_block_num = block_num;
      period_share = share;
    }

    function get_shareholders_count() public view returns(uint){
      return shareholders.length;
    }

    function get_shareholder_amount_with_index(uint index) public view only_signer returns(address account, uint amount) {
      require(index>=0 && index<shareholders.length);
      return (shareholders[index], share_amounts[shareholders[index]]);
    }

    function get_shareholder_amount_with_account(address account) public view only_signer returns(uint amount){
      return share_amounts[account];
    }
}