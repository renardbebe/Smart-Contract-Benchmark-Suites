 

pragma solidity ^0.4.15;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Controller {
     
    address public developer = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;

    modifier onlyOwner {
        require(msg.sender == developer);
        _;
    }
}

contract SanityPools is Controller {

     
    mapping (uint256 => mapping (address => uint256)) balances;
     
    Pool[100] pools;
     
    uint256 index_active = 0;
     
    uint256 public week_in_blocs = 39529;

    modifier validIndex(uint256 _index){
        require(_index <= index_active);
        _;
    }

    struct Pool {
        string name;
         
        uint256 min_amount;
        uint256 max_amount;
         
        address sale;
        ERC20 token;
         
        uint256 pool_eth_value;
         
        bool bought_tokens;
        uint256 buy_block;
    }

     
    function createPool(string _name, uint256 _min, uint256 _max) onlyOwner {
        require(index_active < 100);
         
        pools[index_active] = Pool(_name, _min, _max, 0x0, ERC20(0x0), 0, false, 0);
         
        index_active += 1;
    }

    function setSale(uint256 _index, address _sale) onlyOwner validIndex(_index) {
        Pool storage pool = pools[_index];
        require(pool.sale == 0x0);
        pool.sale = _sale;
    }

    function setToken(uint256 _index, address _token) onlyOwner validIndex(_index) {
        Pool storage pool = pools[_index];
        pool.token = ERC20(_token);
    }

    function buyTokens(uint256 _index) onlyOwner validIndex(_index) {
        Pool storage pool = pools[_index];
        require(pool.pool_eth_value >= pool.min_amount);
        require(pool.pool_eth_value <= pool.max_amount || pool.max_amount == 0);
        require(!pool.bought_tokens);
         
        require(pool.sale != 0x0);
         
        pool.buy_block = block.number;
         
        pool.bought_tokens = true;
         
        pool.sale.transfer(pool.pool_eth_value);
    }

    function emergency_withdraw(uint256 _index, address _token) onlyOwner validIndex(_index) {
         
         
        Pool storage pool = pools[_index];
        require(block.number >= (pool.buy_block + week_in_blocs));
        ERC20 token = ERC20(_token);
        uint256 contract_token_balance = token.balanceOf(address(this));
        require (contract_token_balance != 0);
         
        require(token.transfer(msg.sender, contract_token_balance));
    }

    function change_delay(uint256 _delay) onlyOwner {
        week_in_blocs = _delay;
    }

     
    function getPoolName(uint256 _index) validIndex(_index) constant returns (string) {
        Pool storage pool = pools[_index];
        return pool.name;
    }

    function refund(uint256 _index) validIndex(_index) {
        Pool storage pool = pools[_index];
         
        require(!pool.bought_tokens);
        uint256 eth_to_withdraw = balances[_index][msg.sender];
         
        balances[_index][msg.sender] = 0;
         
        pool.pool_eth_value -= eth_to_withdraw;
        msg.sender.transfer(eth_to_withdraw);
    }

    function withdraw(uint256 _index) validIndex(_index) {
        Pool storage pool = pools[_index];
         
        require(pool.bought_tokens);
        uint256 contract_token_balance = pool.token.balanceOf(address(this));
         
        require(contract_token_balance != 0);
         
        uint256 tokens_to_withdraw = (balances[_index][msg.sender] * contract_token_balance) / pool.pool_eth_value;
         
        pool.pool_eth_value -= balances[_index][msg.sender];
         
        balances[_index][msg.sender] = 0;
         
        uint256 fee = tokens_to_withdraw / 100;
         
        require(pool.token.transfer(msg.sender, tokens_to_withdraw - fee));
         
        require(pool.token.transfer(developer, fee));
    }

    function contribute(uint256 _index) validIndex(_index) payable {
        Pool storage pool = pools[_index];
        require(!pool.bought_tokens);
         
        require(pool.pool_eth_value+msg.value <= pool.max_amount || pool.max_amount == 0);
         
        pool.pool_eth_value += msg.value;
         
        balances[_index][msg.sender] += msg.value;
    }
}