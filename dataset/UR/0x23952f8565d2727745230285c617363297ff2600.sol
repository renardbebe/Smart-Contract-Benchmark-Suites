 

pragma solidity ^0.4.24;

 
contract Z_ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Z_ERC20 is Z_ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract Z_BasicToken is Z_ERC20Basic {
   
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract Z_StandardToken is Z_ERC20, Z_BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;
 
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function transferFromByAdmin(address _from, address _to, uint256 _value) internal returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
     

    balances[_from] -= _value;
    balances[_to] += _value;

    emit Transfer(_from, _to, _value);
    return true;
  }


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + (_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue - (_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract Z_Ownable {
  address public owner;
  mapping (address => bool) internal admin_accounts;

   
  constructor() public {
     
    owner = msg.sender;
     
    admin_accounts[msg.sender]= true;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner );
    _;
  }

   
  function  isOwner() internal view returns (bool) {
    return (msg.sender == owner );
    
  }
  
   
  modifier onlyAdmin() {
    require (admin_accounts[msg.sender]==true);
    _;
  }

   
  function  isAdmin() internal view returns (bool) {
    return  (admin_accounts[msg.sender]==true);
    
  }
 
}


 

contract NowToken is Z_StandardToken, Z_Ownable {
    string  public  constant name = "NOW";
    string  public  constant symbol = "NOW";
    uint8   public  constant decimals = 18;  

     
    uint256 internal constant _totalTokenAmount = 30 * (10 ** 9) * (10 ** 18);

    uint256 internal constant WEI_PER_ETHER= 1000000000000000000;  
    uint256 internal constant NUM_OF_SALE_STAGES= 5;  

     
    enum Sale_Status {
      Initialized_STATUS,  
      Stage0_Sale_Started_STATUS,  
      Stage0_Sale_Stopped_STATUS,  
      Stage1_Sale_Started_STATUS,  
      Stage1_Sale_Stopped_STATUS,  
      Stage2_Sale_Started_STATUS,  
      Stage2_Sale_Stopped_STATUS,  
      Stage3_Sale_Started_STATUS,  
      Stage3_Sale_Stopped_STATUS,  
      Stage4_Sale_Started_STATUS,  
      Stage4_Sale_Stopped_STATUS,  
      Public_Allowed_To_Trade_STATUS,  
      Stage0_Allowed_To_Trade_STATUS,  
      Closed_STATUS   
    }

     
    Sale_Status  public  sale_status= Sale_Status.Initialized_STATUS;

     
    uint256   public  sale_stage_index= 0;  

     
    uint256  public  when_initialized= 0;

     
    uint256  public  when_public_allowed_to_trade_started= 0;

     
    uint256  public  when_stage0_allowed_to_trade_started= 0;

     
    uint256 [NUM_OF_SALE_STAGES] public  when_stageN_sale_started;

     
    uint256 [NUM_OF_SALE_STAGES] public  when_stageN_sale_stopped;

     
    uint256 public sold_tokens_total= 0;

     
    uint256 public raised_ethers_total= 0;

     
    uint256[NUM_OF_SALE_STAGES] public sold_tokens_per_stage;

     
    uint256[NUM_OF_SALE_STAGES] public raised_ethers_per_stage;

     
    uint256[NUM_OF_SALE_STAGES] public target_ethers_per_stage= [
       1000 * WEI_PER_ETHER,  
       9882 * WEI_PER_ETHER,  
      11454 * WEI_PER_ETHER,  
      11200 * WEI_PER_ETHER,  
      11667 * WEI_PER_ETHER   
    ];

     
    uint256[NUM_OF_SALE_STAGES] internal  sale_price_per_stage_wei_per_now = [
      uint256(1000000000000000000/ uint256(100000)), 
      uint256(1000000000000000000/ uint256(38000)),  
      uint256(1000000000000000000/ uint256(23000)),  
      uint256(1000000000000000000/ uint256(17000)),  
      uint256(1000000000000000000/ uint256(10000))   
    ];

     
    struct history_token_transfer_obj {
      address _from;
      address _to;
      uint256 _token_value;  
      uint256 _when; 
    }

     
    struct history_token_burning_obj {
      address _from;
      uint256 _token_value_burned;  
      uint256 _when; 
    }

     
    history_token_transfer_obj[] internal history_token_transfer;

     
    history_token_burning_obj[]  internal history_token_burning;

     
    mapping (address => uint256) internal sale_amount_stage0_account;
    mapping (address => uint256) internal sale_amount_stage1_account;
    mapping (address => uint256) internal sale_amount_stage2_account;
    mapping (address => uint256) internal sale_amount_stage3_account;
    mapping (address => uint256) internal sale_amount_stage4_account;

    
     
    mapping (address => uint256) internal holders_received_accumul;

     
    address[] public holders;

     
    address[] public holders_stage0_sale;
    address[] public holders_stage1_sale;
    address[] public holders_stage2_sale;
    address[] public holders_stage3_sale;
    address[] public holders_stage4_sale;
    
     
    address[] public holders_trading;

     
    address[] public holders_burned;

     
    address[] public holders_frozen;

     
    mapping (address => uint256) public burned_amount;

     
    uint256 public totalBurned= 0;

     
    uint256 public totalEtherWithdrawed= 0;

     
    mapping (address => uint256) internal account_frozen_time;

     
    mapping (address => mapping (string => uint256)) internal traded_monthly;

     
    address[] public cryptocurrency_exchange_company_accounts;

    
     
 
    event AddNewAdministrator(address indexed _admin, uint256 indexed _when);
    event RemoveAdministrator(address indexed _admin, uint256 indexed _when);
  
     
    function z_admin_add_admin(address _newAdmin) public onlyOwner {
      require(_newAdmin != address(0));
      admin_accounts[_newAdmin]=true;
    
      emit AddNewAdministrator(_newAdmin, block.timestamp);
    }
  
     
    function z_admin_remove_admin(address _oldAdmin) public onlyOwner {
      require(_oldAdmin != address(0));
      require(admin_accounts[_oldAdmin]==true);
      admin_accounts[_oldAdmin]=false;
    
      emit RemoveAdministrator(_oldAdmin, block.timestamp);
    }
  
    event AddNewExchangeAccount(address indexed _exchange_account, uint256 indexed _when);

     
    function z_admin_add_exchange(address _exchange_account) public onlyAdmin {
      require(_exchange_account != address(0));
      cryptocurrency_exchange_company_accounts.push(_exchange_account);
    
      emit AddNewExchangeAccount(_exchange_account, block.timestamp);
    }
 
    event SaleTokenPriceSet(uint256 _stage_index, uint256 _wei_per_now_value, uint256 indexed _when);

     
    function z_admin_set_sale_price(uint256 _how_many_wei_per_now) public
        onlyAdmin 
    {
        if(_how_many_wei_per_now == 0) revert();
        if(sale_stage_index >= 5) revert();
        sale_price_per_stage_wei_per_now[sale_stage_index] = _how_many_wei_per_now;
        emit SaleTokenPriceSet(sale_stage_index, _how_many_wei_per_now, block.timestamp);
    }

     
    function CurrentSalePrice() public view returns (uint256 _sale_price, uint256 _current_sale_stage_index)  {
        if(sale_stage_index >= 5) revert();
        _current_sale_stage_index= sale_stage_index;
        _sale_price= sale_price_per_stage_wei_per_now[sale_stage_index];
    }


    event InitializedStage(uint256 indexed _when);
    event StartStage0TokenSale(uint256 indexed _when);
    event StartStage1TokenSale(uint256 indexed _when);
    event StartStage2TokenSale(uint256 indexed _when);
    event StartStage3TokenSale(uint256 indexed _when);
    event StartStage4TokenSale(uint256 indexed _when);

     
    function start_StageN_Sale(uint256 _new_sale_stage_index) internal
    {
        if(sale_status==Sale_Status.Initialized_STATUS || sale_stage_index+1<= _new_sale_stage_index)
           sale_stage_index= _new_sale_stage_index;
        else
           revert();
        sale_status= Sale_Status(1 + sale_stage_index * 2);  
        when_stageN_sale_started[sale_stage_index]= block.timestamp;
        if(sale_stage_index==0) emit StartStage0TokenSale(block.timestamp); 
        if(sale_stage_index==1) emit StartStage1TokenSale(block.timestamp); 
        if(sale_stage_index==2) emit StartStage2TokenSale(block.timestamp); 
        if(sale_stage_index==3) emit StartStage3TokenSale(block.timestamp); 
        if(sale_stage_index==4) emit StartStage4TokenSale(block.timestamp); 
    }



    event StopStage0TokenSale(uint256 indexed _when);
    event StopStage1TokenSale(uint256 indexed _when);
    event StopStage2TokenSale(uint256 indexed _when);
    event StopStage3TokenSale(uint256 indexed _when);
    event StopStage4TokenSale(uint256 indexed _when);

     
    function stop_StageN_Sale(uint256 _old_sale_stage_index) internal 
    {
        if(sale_stage_index != _old_sale_stage_index)
           revert();
        sale_status= Sale_Status(2 + sale_stage_index * 2);  
        when_stageN_sale_stopped[sale_stage_index]= block.timestamp;
        if(sale_stage_index==0) emit StopStage0TokenSale(block.timestamp); 
        if(sale_stage_index==1) emit StopStage1TokenSale(block.timestamp); 
        if(sale_stage_index==2) emit StopStage2TokenSale(block.timestamp); 
        if(sale_stage_index==3) emit StopStage3TokenSale(block.timestamp); 
        if(sale_stage_index==4) emit StopStage4TokenSale(block.timestamp); 
    }



    event StartTradePublicSaleTokens(uint256 indexed _when);

     
    function start_Public_Trade() internal
        onlyAdmin
    {
         
        Sale_Status new_sale_status= Sale_Status(2 + sale_stage_index * 2);
        if(new_sale_status > sale_status)
          stop_StageN_Sale(sale_stage_index);

        sale_status= Sale_Status.Public_Allowed_To_Trade_STATUS;
        when_public_allowed_to_trade_started= block.timestamp;
        emit StartTradePublicSaleTokens(block.timestamp); 
    }

    event StartTradeStage0SaleTokens(uint256 indexed _when);

     
    function start_Stage0_Trade() internal
        onlyAdmin
    {
        if(sale_status!= Sale_Status.Public_Allowed_To_Trade_STATUS) revert();
        
         

        uint32 stage0_locked_year= 1;
 
        bool is_debug= false;  
        if(is_debug==false && block.timestamp <  stage0_locked_year*365*24*60*60
            + when_public_allowed_to_trade_started  )  
	      revert();
        if(is_debug==true  && block.timestamp <  stage0_locked_year*10*60
            + when_public_allowed_to_trade_started  )  
	      revert();
	      
        sale_status= Sale_Status.Stage0_Allowed_To_Trade_STATUS;
        when_stage0_allowed_to_trade_started= block.timestamp;
        emit StartTradeStage0SaleTokens(block.timestamp); 
    }




    event CreateTokenContract(uint256 indexed _when);

     
    constructor() public
    {
        totalSupply = _totalTokenAmount;
        balances[msg.sender] = _totalTokenAmount;

        sale_status= Sale_Status.Initialized_STATUS;
        sale_stage_index= 0;

        when_initialized= block.timestamp;

        holders.push(msg.sender); 
        holders_received_accumul[msg.sender] += _totalTokenAmount;

        emit Transfer(address(0x0), msg.sender, _totalTokenAmount);
        emit InitializedStage(block.timestamp);
        emit CreateTokenContract(block.timestamp); 
    }




     
    modifier validTransaction( address _from, address _to, uint256 _value)
    {
        require(_to != address(0x0));
        require(_to != _from);
        require(_value > 0);
        if(isAdmin()==false)  {
	     
	    if(account_frozen_time[_from] > 0) revert();
	    if(_value == 0 ) revert();

             
            if(sale_status < Sale_Status.Public_Allowed_To_Trade_STATUS) revert();

             
            if( sale_amount_stage0_account[_from] > 0 ) {
                if(sale_status < Sale_Status.Stage0_Allowed_To_Trade_STATUS)  
                    revert();
            }  else {
            }
  	 }
        _;
    }


    event TransferToken(address indexed _from_whom,address indexed _to_whom,
         uint _token_value, uint256 indexed _when);
    event TransferTokenFrom(address indexed _from_whom,address indexed _to_whom, address _agent,
	 uint _token_value, uint256 indexed _when);
    event TransferTokenFromByAdmin(address indexed _from_whom,address indexed _to_whom, address _admin, 
 	 uint _token_value, uint256 indexed _when);

     
    function transfer(address _to, uint _value) public 
        validTransaction(msg.sender, _to,  _value)
    returns (bool _success) 
    {
        _success= super.transfer(_to, _value);
        if(_success==false) revert();

  	emit TransferToken(msg.sender,_to,_value,block.timestamp);

	 
        if(holders_received_accumul[_to]==0x0) {
	    
           holders.push(_to); 
           holders_trading.push(_to);
	   emit NewHolderTrading(_to, block.timestamp);
        }
        holders_received_accumul[_to] += _value;

	 
        history_token_transfer.push( history_token_transfer_obj( {
	       _from: msg.sender,
	       _to: _to,
	       _token_value: _value,
	       _when: block.timestamp
        } ) );
    }

     
    function transferFrom(address _from, address _to, uint _value) public 
        validTransaction(_from, _to, _value)
    returns (bool _success) 
    {
        if(isAdmin()==true) {
             
            emit TransferTokenFromByAdmin(_from,_to,msg.sender,_value,block.timestamp);
            _success= super.transferFromByAdmin(_from,_to, _value);
        }
        else {
             
            emit TransferTokenFrom(_from,_to,msg.sender,_value,block.timestamp);
            _success= super.transferFrom(_from, _to, _value);
        }

        if(_success==false) revert();
        
	 
        if(holders_received_accumul[_to]==0x0) {
	    
           holders.push(_to); 
           holders_trading.push(_to); 
	   emit NewHolderTrading(_to, block.timestamp);
        }
        holders_received_accumul[_to] += _value;

	 
        history_token_transfer.push( history_token_transfer_obj( {
	       _from: _from,
	       _to: _to,
	       _token_value: _value,
	       _when: block.timestamp
        } ) );

    }

    
    event IssueTokenSale(address indexed _buyer, uint _ether_value, uint _token_value,
           uint _exchange_rate_now_per_wei, uint256 indexed _when);

     
    function () public payable {
        buy();
    }

    event NewHolderTrading(address indexed _new_comer, uint256 indexed _when);
    event NewHolderSale(address indexed _new_comer, uint256 indexed _when);
    
     
    function buy() public payable {
        if(sale_status < Sale_Status.Stage0_Sale_Started_STATUS) 
           revert();
        
        if(sale_status > Sale_Status.Stage4_Sale_Stopped_STATUS) 
           revert();
        
        if((uint256(sale_status)%2)!=1)  revert();  
        if(isAdmin()==true)  revert();  
	  
        uint256 tokens;
        
        uint256 wei_per_now= sale_price_per_stage_wei_per_now[sale_stage_index];

         
        if (msg.value <  wei_per_now) revert();

         
	tokens = uint256( msg.value /  wei_per_now );
      
        if (tokens + sold_tokens_total > totalSupply) revert();

         
	if(sale_stage_index==0) sale_amount_stage0_account[msg.sender] += tokens; else	
	if(sale_stage_index==1) sale_amount_stage1_account[msg.sender] += tokens; else	
	if(sale_stage_index==2) sale_amount_stage2_account[msg.sender] += tokens; else	
	if(sale_stage_index==3) sale_amount_stage3_account[msg.sender] += tokens; else	
	if(sale_stage_index==4) sale_amount_stage4_account[msg.sender] += tokens;	
	sold_tokens_per_stage[sale_stage_index] += tokens;
        sold_tokens_total += tokens;

         
	raised_ethers_per_stage[sale_stage_index] +=  msg.value;
        raised_ethers_total +=  msg.value;

        super.transferFromByAdmin(owner, msg.sender, tokens);

	 
        if(holders_received_accumul[msg.sender]==0x0) {
	    
           holders.push(msg.sender); 
	   if(sale_stage_index==0) holders_stage0_sale.push(msg.sender); else 
	   if(sale_stage_index==1) holders_stage1_sale.push(msg.sender); else 
	   if(sale_stage_index==2) holders_stage2_sale.push(msg.sender); else 
	   if(sale_stage_index==3) holders_stage3_sale.push(msg.sender); else 
	   if(sale_stage_index==4) holders_stage4_sale.push(msg.sender); 
	   emit NewHolderSale(msg.sender, block.timestamp);
        }
        holders_received_accumul[msg.sender] += tokens;

        emit IssueTokenSale(msg.sender, msg.value, tokens, wei_per_now, block.timestamp);
        
         
	if( target_ethers_per_stage[sale_stage_index] <= raised_ethers_per_stage[sale_stage_index])
    	    stop_StageN_Sale(sale_stage_index);
    }


    event FreezeAccount(address indexed _account_to_freeze, uint256 indexed _when);
    event UnfreezeAccount(address indexed _account_to_unfreeze, uint256 indexed _when);
    
     
    function z_admin_freeze(address _account_to_freeze) public onlyAdmin   {
        account_frozen_time[_account_to_freeze]= block.timestamp;
        holders_frozen.push(_account_to_freeze);
        emit FreezeAccount(_account_to_freeze,block.timestamp); 
    }

     
    function z_admin_unfreeze(address _account_to_unfreeze) public onlyAdmin   {
        account_frozen_time[_account_to_unfreeze]= 0;  
        emit UnfreezeAccount(_account_to_unfreeze,block.timestamp); 
    }




    event CloseTokenContract(uint256 indexed _when);

     
    function closeContract() onlyAdmin internal {
	if(sale_status < Sale_Status.Stage0_Allowed_To_Trade_STATUS)  revert();
	if(totalSupply > 0)  revert();
    	address ScAddress = this;
        emit CloseTokenContract(block.timestamp); 
        emit WithdrawEther(owner,ScAddress.balance,block.timestamp); 
	selfdestruct(owner);
    } 



     
    function ContractEtherBalance() public view
    returns (
      uint256 _current_ether_balance,
      uint256 _ethers_withdrawn,
      uint256 _ethers_raised_total 
     ) {
	_current_ether_balance= address(this).balance;
	_ethers_withdrawn= totalEtherWithdrawed;
	_ethers_raised_total= raised_ethers_total;
    } 

    event WithdrawEther(address indexed _addr, uint256 _value, uint256 indexed _when);

     
    function z_admin_withdraw_ether(uint256 _withdraw_wei_value) onlyAdmin public {
    	address ScAddress = this;
    	if(_withdraw_wei_value > ScAddress.balance) revert();
    	 
    	if(owner.send(_withdraw_wei_value)==false) revert();
        totalEtherWithdrawed += _withdraw_wei_value;
        emit WithdrawEther(owner,_withdraw_wei_value,block.timestamp); 
    } 


     
    function list_active_holders_and_balances(uint _max_num_of_items_to_display) public view 
      returns (uint _num_of_active_holders,address[] _active_holders,uint[] _token_balances){
      uint len = holders.length;
      _num_of_active_holders = 0;
      if(_max_num_of_items_to_display==0) _max_num_of_items_to_display=1;
      for (uint i = len-1 ; i >= 0 ; i--) {
         if( balances[ holders[i] ] != 0x0) _num_of_active_holders++;
         if(_max_num_of_items_to_display == _num_of_active_holders) break;
      }
      _active_holders = new address[](_num_of_active_holders);
      _token_balances = new uint[](_num_of_active_holders);
      uint num=0;
      for (uint j = len-1 ; j >= 0 && _num_of_active_holders > num ; j--) {
         address addr = holders[j];
         if( balances[ addr ] == 0x0) continue;  
         _active_holders[num] = addr;
         _token_balances[num] = balances[addr];
         num++;
      }
    }


     
    function list_history_of_token_transfer(uint _max_num_of_items_to_display) public view 
      returns (uint _num,address[] _senders,address[] _receivers,uint[] _tokens,uint[] _whens){
      uint len = history_token_transfer.length;
      uint n= len;
      if(_max_num_of_items_to_display == 0) _max_num_of_items_to_display= 1;
      if(_max_num_of_items_to_display <  n) n= _max_num_of_items_to_display;
      _senders = new address[](n);
      _receivers = new address[](n);
      _tokens = new uint[](n);
      _whens = new uint[](n);
      _num=0;
      for (uint j = len-1 ; j >= 0 && n > _num ; j--) {
         history_token_transfer_obj storage obj= history_token_transfer[j];
         _senders[_num]= obj._from;
         _receivers[_num]= obj._to;
         _tokens[_num]=  obj._token_value;
         _whens[_num]=   obj._when;
         _num++;
      }
    }

     
    function list_history_of_token_transfer_filtered_by_addr(address _addr) public view 
      returns (uint _num,address[] _senders,address[] _receivers,uint[] _tokens,uint[] _whens){
      uint len = history_token_transfer.length;
      uint _max_num_of_items_to_display= 0;
      history_token_transfer_obj storage obj= history_token_transfer[0];
      uint j;
      for (j = len-1 ; j >= 0 ; j--) {
         obj= history_token_transfer[j];
         if(obj._from== _addr || obj._to== _addr) _max_num_of_items_to_display++;
      }
      if(_max_num_of_items_to_display == 0) _max_num_of_items_to_display= 1;
      _senders = new address[](_max_num_of_items_to_display);
      _receivers = new address[](_max_num_of_items_to_display);
      _tokens = new uint[](_max_num_of_items_to_display);
      _whens = new uint[](_max_num_of_items_to_display);
      _num=0;
      for (j = len-1 ; j >= 0 && _max_num_of_items_to_display > _num ; j--) {
         obj= history_token_transfer[j];
         if(obj._from!= _addr && obj._to!= _addr) continue;
         _senders[_num]= obj._from;
         _receivers[_num]= obj._to;
         _tokens[_num]=  obj._token_value;
         _whens[_num]=   obj._when;
         _num++;
      }
    }

     
    function list_frozen_accounts(uint _max_num_of_items_to_display) public view
      returns (uint _num,address[] _frozen_holders,uint[] _whens){
      uint len = holders_frozen.length;
      uint num_of_frozen_holders = 0;
      if(_max_num_of_items_to_display==0) _max_num_of_items_to_display=1;
      for (uint i = len-1 ; i >= 0 ; i--) {
          
         if( account_frozen_time[ holders_frozen[i] ] > 0x0) num_of_frozen_holders++;
         if(_max_num_of_items_to_display == num_of_frozen_holders) break;
      }
      _frozen_holders = new address[](num_of_frozen_holders);
      _whens = new uint[](num_of_frozen_holders);
      _num=0;
      for (uint j = len-1 ; j >= 0 && num_of_frozen_holders > _num ; j--) {
         address addr= holders_frozen[j];
         uint256 when= account_frozen_time[ addr ];
         if( when == 0x0) continue;  
         _frozen_holders[_num]= addr;
         _whens[_num]= when;
         _num++;
      }
    }


     
    function z_admin_next_status(Sale_Status _next_status) onlyAdmin public {
      if(_next_status== Sale_Status.Stage0_Sale_Started_STATUS) { start_StageN_Sale(0); return;}  
      if(_next_status== Sale_Status.Stage0_Sale_Stopped_STATUS) { stop_StageN_Sale(0); return;}  
      if(_next_status== Sale_Status.Stage1_Sale_Started_STATUS) { start_StageN_Sale(1); return;}  
      if(_next_status== Sale_Status.Stage1_Sale_Stopped_STATUS) { stop_StageN_Sale(1); return;}  
      if(_next_status== Sale_Status.Stage2_Sale_Started_STATUS) { start_StageN_Sale(2); return;}  
      if(_next_status== Sale_Status.Stage2_Sale_Stopped_STATUS) { stop_StageN_Sale(2); return;}  
      if(_next_status== Sale_Status.Stage3_Sale_Started_STATUS) { start_StageN_Sale(3); return;}  
      if(_next_status== Sale_Status.Stage3_Sale_Stopped_STATUS) { stop_StageN_Sale(3); return;}  
      if(_next_status== Sale_Status.Stage4_Sale_Started_STATUS) { start_StageN_Sale(4); return;}  
      if(_next_status== Sale_Status.Stage4_Sale_Stopped_STATUS) { stop_StageN_Sale(4); return;}  
      if(_next_status== Sale_Status.Public_Allowed_To_Trade_STATUS) { start_Public_Trade(); return;}  
      if(_next_status== Sale_Status.Stage0_Allowed_To_Trade_STATUS) { start_Stage0_Trade(); return;}  
      if(_next_status== Sale_Status.Closed_STATUS) { closeContract(); return;}  
      revert();
    } 

}