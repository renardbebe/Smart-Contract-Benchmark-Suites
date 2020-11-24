 

pragma solidity ^0.4.13;

 
contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract BitcoineumInterface {
   function mine() payable;
   function claim(uint256 _blockNumber, address forCreditTo);
   function checkMiningAttempt(uint256 _blockNum, address _sender) constant public returns (bool);
   function checkWinning(uint256 _blockNum) constant public returns (bool);
   function transfer(address _to, uint256 _value) returns (bool);
   function balanceOf(address _owner) constant returns (uint256 balance);
   function currentDifficultyWei() constant public returns (uint256);
   }

 
 
 

contract SharkPool is Ownable, ReentrancyGuard {

    string constant public pool_name = "SharkPool 200";

     
    uint256 public pool_percentage = 5;

     
     
    uint256 constant public max_users = 100;

     
    uint256 public total_users = 0;

    uint256 public constant divisible_units = 10000000;

     
    uint256 public contract_period = 100;
    uint256 public mined_blocks = 1;
    uint256 public claimed_blocks = 1;
    uint256 public blockCreationRate = 0;

    BitcoineumInterface base_contract;

    struct user {
        uint256 start_block;
        uint256 end_block;
        uint256 proportional_contribution;
    }

    mapping (address => user) public users;
    mapping (uint256 => uint256) public attempts;
    mapping(address => uint256) balances;
    uint8[] slots;
    address[256] public active_users;  

    function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
    }

    function set_pool_percentage(uint8 _percentage) external nonReentrant onlyOwner {
        
       require(_percentage < 11);
       pool_percentage = _percentage;
    }


    function find_contribution(address _who) constant external returns (uint256, uint256, uint256, uint256, uint256) {
      if (users[_who].start_block > 0) {
         user memory u = users[_who];
         uint256 remaining_period= 0;
         if (u.end_block > mined_blocks) {
            remaining_period = u.end_block - mined_blocks;
            } else {
            remaining_period = 0;
            }
         return (u.start_block, u.end_block,
                 u.proportional_contribution,
                 u.proportional_contribution * contract_period,
                 u.proportional_contribution * remaining_period);
      }
      return (0,0,0,0,0);
    }

    function allocate_slot(address _who) internal {
       if(total_users < max_users) { 
             
            active_users[total_users] = _who;
            total_users += 1;
          } else {
             
            if (slots.length == 0) {
                 
                revert();
            } else {
               uint8 location = slots[slots.length-1];
               active_users[location] = _who;
               delete slots[slots.length-1];
            }
          }
    }

     function external_to_internal_block_number(uint256 _externalBlockNum) public constant returns (uint256) {
         
        return _externalBlockNum / blockCreationRate;
     }

     function available_slots() public constant returns (uint256) {
        if (total_users < max_users) {
            return max_users - total_users;
        } else {
          return slots.length;
        }
     }
  
   event LogEvent(
       uint256 _info
   );

    function get_bitcoineum_contract_address() public constant returns (address) {
       return 0x73dD069c299A5d691E9836243BcaeC9c8C1D8734;  
    
        
    }

     
     
     
    function distribute_reward(uint256 _totalAttempt, uint256 _balance) internal {
      uint256 remaining_balance = _balance;
      for (uint8 i = 0; i < total_users; i++) {
          address user_address = active_users[i];
          if (user_address > 0 && remaining_balance != 0) {
              uint256 proportion = users[user_address].proportional_contribution;
              uint256 divided_portion = (proportion * divisible_units) / _totalAttempt;
              uint256 payout = (_balance * divided_portion) / divisible_units;
              if (payout > remaining_balance) {
                 payout = remaining_balance;
              }
              balances[user_address] = balances[user_address] + payout;
              remaining_balance = remaining_balance - payout;
          }
      }
    }

    function SharkPool() {
      blockCreationRate = 50;  
      base_contract = BitcoineumInterface(get_bitcoineum_contract_address());
    }

    function current_external_block() public constant returns (uint256) {
        return block.number;
    }


    function calculate_minimum_contribution() public constant returns (uint256)  {
       return base_contract.currentDifficultyWei() / 10000000 * contract_period;
    }

     
    function () payable {
         require(msg.value >= calculate_minimum_contribution());

          
         user storage current_user = users[msg.sender];

          
         if (current_user.start_block > 0) {
            if (current_user.end_block > mined_blocks) {
                uint256 periods_left = current_user.end_block - mined_blocks;
                uint256 amount_remaining = current_user.proportional_contribution * periods_left;
                amount_remaining = amount_remaining + msg.value;
                amount_remaining = amount_remaining / contract_period;
                current_user.proportional_contribution = amount_remaining;
            } else {
               current_user.proportional_contribution = msg.value / contract_period;
            }

           
          do_redemption();

          } else {
               current_user.proportional_contribution = msg.value / contract_period;
               allocate_slot(msg.sender);
          }
          current_user.start_block = mined_blocks;
          current_user.end_block = mined_blocks + contract_period;
         }

    
     
   function mine() external nonReentrant
   {
      
     uint256 _blockNum = external_to_internal_block_number(current_external_block());
     require(!base_contract.checkMiningAttempt(_blockNum, this));

      

     uint256 total_attempt = 0;
     uint8 total_ejected = 0; 

     for (uint8 i=0; i < total_users; i++) {
         address user_address = active_users[i];
         if (user_address > 0) {
              
             user memory u = users[user_address];
             if (u.end_block <= mined_blocks) {
                 
                 
                if (total_ejected < 10) {
                    delete active_users[i];
                    slots.push(i);
                    delete users[active_users[i]];
                    total_ejected = total_ejected + 1;
                }
             } else {
                
               total_attempt = total_attempt + u.proportional_contribution;
             }
         }
     }
     if (total_attempt > 0) {
         
        attempts[_blockNum] = total_attempt;
        base_contract.mine.value(total_attempt)();
        mined_blocks = mined_blocks + 1;
     }
   }

   function claim(uint256 _blockNumber, address forCreditTo)
                  nonReentrant
                  external returns (bool) {
                  
                   
                  require(base_contract.checkWinning(_blockNumber));

                  uint256 initial_balance = base_contract.balanceOf(this);

                   
                  base_contract.claim(_blockNumber, this);

                  uint256 balance = base_contract.balanceOf(this);
                  uint256 total_attempt = attempts[_blockNumber];

                  distribute_reward(total_attempt, balance - initial_balance);
                  claimed_blocks = claimed_blocks + 1;
                  }

   function do_redemption() internal {
     uint256 balance = balances[msg.sender];
     if (balance > 0) {
        uint256 owner_cut = (balance / 100) * pool_percentage;
        uint256 remainder = balance - owner_cut;
        if (owner_cut > 0) {
            base_contract.transfer(owner, owner_cut);
        }
        base_contract.transfer(msg.sender, remainder);
        balances[msg.sender] = 0;
    }
   }

   function redeem() external nonReentrant
     {
        do_redemption();
     }

   function checkMiningAttempt(uint256 _blockNum, address _sender) constant public returns (bool) {
      return base_contract.checkMiningAttempt(_blockNum, _sender);
   }
   
   function checkWinning(uint256 _blockNum) constant public returns (bool) {
     return base_contract.checkWinning(_blockNum);
   }

}