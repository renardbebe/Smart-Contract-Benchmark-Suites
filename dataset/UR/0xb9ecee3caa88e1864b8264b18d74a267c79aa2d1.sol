 

contract EthereumRouletteInterface {

   
  address public owner;
   
   
   
  uint public locked_funds_for_revealed_spins;
   
   
  uint public owner_time_limit;
   
  uint public fraction;
   
  uint public max_bet_this_spin;
   
   
   
   
   
  Spin[] public spins;

  struct Spin {
     
     
     
     
    uint total_payout;
     
    bytes32 commit_hash;
     
    uint8 spin_result;
     
     
    bytes32 nonce;
     
     
    mapping(uint8 => uint) total_bet_on_number;
     
    mapping(address => mapping(uint8 => Bet)) bets;
     
     
    bool owner_took_too_long;
     
    uint time_of_latest_reveal;
  }

  struct Bet {
    uint amount;
     
    bool already_paid;
  }

   
  modifier onlyOwner {}
   
  modifier noEther {}
   
  modifier etherRequired {}

   
  function player_make_bet(uint8 spin_result) etherRequired;

   
  function player_collect_winnings(uint spin_num) noEther;

   
   
   
  function player_declare_taking_too_long() noEther;

   
   
   
   
   
   
   
   
   
   
  function owner_reveal_and_commit(uint8 spin_result, bytes32 nonce, bytes32 commit_hash) onlyOwner noEther;

   
  function owner_set_time_limit(uint new_time_limit) onlyOwner noEther;

   
  function owner_deposit() onlyOwner etherRequired;

   
   
  function owner_withdraw(uint amount) onlyOwner noEther;

   
  function owner_set_fraction(uint _fraction) onlyOwner noEther;

  function owner_transfer_ownership(address new_owner) onlyOwner noEther;

  event MadeBet(uint amount, uint8 spin_result, address player_addr);
  event Revealed(uint spin_number, uint8 spin_result);
}


contract EthereumRoulette is EthereumRouletteInterface {

  modifier onlyOwner {if (msg.sender != owner) throw; _}

  modifier noEther {if (msg.value > 0) throw; _}

  modifier etherRequired {if (msg.value == 0) throw; _}

  function EthereumRoulette() {
    owner = msg.sender;
    fraction = 800;
    owner_time_limit = 7 days;
     
     
    bytes32 first_num_hash = 0x3c81cf7279de81901303687979a6b62fdf04ec93480108d2ef38090d6135ad9f;
    bytes32 second_num_hash = 0xb1540f17822cbe4daef5f1d96662b2dc92c5f9a2411429faaf73555d3149b68e;
    spins.length++;
    spins[spins.length - 1].commit_hash = first_num_hash;
    spins.length++;
    spins[spins.length - 1].commit_hash = second_num_hash;
    max_bet_this_spin = address(this).balance / fraction;
  }

  function player_make_bet(uint8 spin_result) etherRequired {
    Spin second_unrevealed_spin = spins[spins.length - 1];
    if (second_unrevealed_spin.owner_took_too_long
        || spin_result > 37
        || msg.value + second_unrevealed_spin.total_bet_on_number[spin_result] > max_bet_this_spin
         
        || msg.value * 36 + reserved_funds() > address(this).balance) {
      throw;
    }
    Bet b = second_unrevealed_spin.bets[msg.sender][spin_result];
    b.amount += msg.value;
    second_unrevealed_spin.total_bet_on_number[spin_result] += msg.value;
    second_unrevealed_spin.total_payout += msg.value * 36;
    if (second_unrevealed_spin.time_of_latest_reveal == 0) {
      second_unrevealed_spin.time_of_latest_reveal = now + owner_time_limit;
    }
    MadeBet(msg.value, spin_result, msg.sender);
  }

  function player_collect_winnings(uint spin_num) noEther {
    Spin s = spins[spin_num];
    if (spin_num >= spins.length - 2) {
      throw;
    }
    if (s.owner_took_too_long) {
      bool at_least_one_number_paid = false;
      for (uint8 roulette_num = 0; roulette_num < 38; roulette_num++) {
        Bet messed_up_bet = s.bets[msg.sender][roulette_num];
        if (messed_up_bet.already_paid) {
          throw;
        }
        if (messed_up_bet.amount > 0) {
          msg.sender.send(messed_up_bet.amount * 36);
          locked_funds_for_revealed_spins -= messed_up_bet.amount * 36;
          messed_up_bet.already_paid = true;
          at_least_one_number_paid = true;
        }
      }
      if (!at_least_one_number_paid) {
         
        throw;
      }
    } else {
      Bet b = s.bets[msg.sender][s.spin_result];
      if (b.already_paid || b.amount == 0) {
        throw;
      }
      msg.sender.send(b.amount * 36);
      locked_funds_for_revealed_spins -= b.amount * 36;
      b.already_paid = true;
    }
  }

  function player_declare_taking_too_long() noEther {
    Spin first_unrevealed_spin = spins[spins.length - 2];
    bool first_spin_too_long = first_unrevealed_spin.time_of_latest_reveal != 0
        && now > first_unrevealed_spin.time_of_latest_reveal;
    Spin second_unrevealed_spin = spins[spins.length - 1];
    bool second_spin_too_long = second_unrevealed_spin.time_of_latest_reveal != 0
        && now > second_unrevealed_spin.time_of_latest_reveal;
    if (!(first_spin_too_long || second_spin_too_long)) {
      throw;
    }
    first_unrevealed_spin.owner_took_too_long = true;
    second_unrevealed_spin.owner_took_too_long = true;
    locked_funds_for_revealed_spins += (first_unrevealed_spin.total_payout + second_unrevealed_spin.total_payout);
  }

  function () {
     
    throw;
  }

  function commit(bytes32 commit_hash) internal {
    uint spin_num = spins.length++;
    Spin second_unrevealed_spin = spins[spins.length - 1];
    second_unrevealed_spin.commit_hash = commit_hash;
    max_bet_this_spin = (address(this).balance - reserved_funds()) / fraction;
  }

  function owner_reveal_and_commit(uint8 spin_result, bytes32 nonce, bytes32 commit_hash) onlyOwner noEther {
    Spin first_unrevealed_spin = spins[spins.length - 2];
    if (!first_unrevealed_spin.owner_took_too_long) {
      if (sha3(spin_result, nonce) != first_unrevealed_spin.commit_hash || spin_result > 37) {
        throw;
      }
      first_unrevealed_spin.spin_result = spin_result;
      first_unrevealed_spin.nonce = nonce;
      locked_funds_for_revealed_spins += first_unrevealed_spin.total_bet_on_number[spin_result] * 36;
      Revealed(spins.length - 2, spin_result);
    }
     
     
    commit(commit_hash);
  }

  function owner_set_time_limit(uint new_time_limit) onlyOwner noEther {
    if (new_time_limit > 2 weeks) {
       
       
      throw;
    }
    owner_time_limit = new_time_limit;
  }

  function owner_deposit() onlyOwner etherRequired {}

  function owner_withdraw(uint amount) onlyOwner noEther {
    if (amount > address(this).balance - reserved_funds()) {
      throw;
    }
    owner.send(amount);
  }

  function owner_set_fraction(uint _fraction) onlyOwner noEther {
    if (_fraction == 0) {
      throw;
    }
    fraction = _fraction;
  }

  function owner_transfer_ownership(address new_owner) onlyOwner noEther {
    owner = new_owner;
  }

  function seconds_left() constant returns(int) {
     
    Spin s = spins[spins.length - 1];
    if (s.time_of_latest_reveal == 0) {
      return -1;
    }
    if (now > s.time_of_latest_reveal) {
      return 0;
    }
    return int(s.time_of_latest_reveal - now);
  }

  function reserved_funds() constant returns (uint) {
     
     
    uint total = locked_funds_for_revealed_spins;
    Spin first_unrevealed_spin = spins[spins.length - 2];
    if (!first_unrevealed_spin.owner_took_too_long) {
      total += first_unrevealed_spin.total_payout;
    }
    Spin second_unrevealed_spin = spins[spins.length - 1];
    if (!second_unrevealed_spin.owner_took_too_long) {
      total += second_unrevealed_spin.total_payout;
    }
    return total;
  }

  function get_hash(uint8 number, bytes32 nonce) constant returns (bytes32) {
    return sha3(number, nonce);
  }

  function bet_this_spin() constant returns (bool) {
     
    Spin s = spins[spins.length - 1];
    return s.time_of_latest_reveal != 0;
  }

  function check_bet(uint spin_num, address player_addr, uint8 spin_result) constant returns (uint) {
     
     
    Spin s = spins[spin_num];
    Bet b = s.bets[player_addr][spin_result];
    return b.amount;
  }

  function current_spin_number() constant returns (uint) {
     
    return spins.length - 1;
  }
}