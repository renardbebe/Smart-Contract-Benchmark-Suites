 

pragma solidity ^0.4.17;

 

 
contract ERC20 {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract ICOSyndicate {
     
    mapping (address => uint256) public balances;
     
    bool public bought_tokens;
     
    uint256 public contract_eth_value;
     
    bool public kill_switch;

     
    uint256 public eth_cap = 30000 ether;
     
    address public developer = 0x91d97da49d3cD71B475F46d719241BD8bb6Af18f;
     
    address public sale;
     
    ERC20 public token;

     
    function set_addresses(address _sale, address _token) public {
         
        require(msg.sender == developer);
         
        require(sale == 0x0);
         
        sale = _sale;
        token = ERC20(_token);
    }

     
    function activate_kill_switch() public {
         
        require(msg.sender == developer);
         
        kill_switch = true;
    }

     
    function withdraw(address user) public {
         
        require(bought_tokens);
         
        if (balances[user] == 0) return;
         
        if (!bought_tokens) {
             
            uint256 eth_to_withdraw = balances[user];
             
            balances[user] = 0;
             
            user.transfer(eth_to_withdraw);
        }
         
        else {
             
            uint256 contract_token_balance = token.balanceOf(address(this));
             
            require(contract_token_balance != 0);
             
            uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
             
            contract_eth_value -= balances[user];
             
            balances[user] = 0;
             
            require(token.transfer(user, tokens_to_withdraw));

        }

    }

     
    function buy() public {
         
        if (bought_tokens) return;
         
        if (kill_switch) return;
         
        require(sale != 0x0);
         
        bought_tokens = true;
         
        contract_eth_value = this.balance;
         
         
        require(sale.call.value(contract_eth_value)());
    }

     
    function () public payable {
         
        require(!kill_switch);
         
        require(!bought_tokens);
         
        require(this.balance < eth_cap);
         
        balances[msg.sender] += msg.value;
    }
}