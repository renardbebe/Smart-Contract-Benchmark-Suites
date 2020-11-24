 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract lucky9io {
     
    uint public house_edge = 0;
    uint public jackpot = 0;
    uint public total_wins_wei = 0;
    uint public total_wins_count = 0;
    uint public total_tickets = 0;

     
    bool private game_alive = true;
    address private owner = 0x5Bf066c70C2B5e02F1C6723E72e82478Fec41201;
    address[] private entries_addresses;
    bytes32[] private entries_blockhash;
    uint private entries_count = 0;

    modifier onlyOwner() {
     require(msg.sender == owner, "Sender not authorized.");
     _;
    }

    function () public payable {
         
        require(game_alive == true);

         
        require(msg.value / 1000000000000000 == 9);

         
        jackpot = jackpot + (msg.value * 85 / 100);
        house_edge = house_edge + (msg.value * 15 / 100);

         
        if(msg.sender == owner) return;

         
        if(entries_count >= entries_addresses.length) {
            entries_addresses.push(msg.sender);
            entries_blockhash.push(blockhash(block.number));
        } else {
            entries_addresses[entries_count] = msg.sender;
            entries_blockhash[entries_count] = blockhash(block.number);
        }
        entries_count++;
        total_tickets++;

        return;
    }

    function pickWinners(uint random_seed) payable public onlyOwner {
        require(entries_count > 0);

        for (uint i=0; i<entries_count; i++) {
            uint lucky_number = uint(keccak256(abi.encodePacked(abi.encodePacked(i+random_seed+uint(entries_addresses[i]), blockhash(block.number)), entries_blockhash[i])));

            if(((lucky_number % 99) % 9) % 3 == 1) {
                 

                 
                uint win_amount = jackpot * 30 / 100;
                if(address(this).balance - house_edge < win_amount) {
                    win_amount = (address(this).balance-house_edge) * 30 / 100;
                }

                jackpot = jackpot - win_amount;

                 
                total_wins_count = total_wins_count + 1;
                total_wins_wei = total_wins_wei + win_amount;

                 
                entries_addresses[i].transfer(win_amount);
            }
        }

        entries_count = 0;
        return;
    }

    function getBalance() constant public returns (uint256) {
        return address(this).balance;
    }

     
    function getEntriesCount() view public onlyOwner returns (uint) {
        return entries_count;
    }

    function stopGame() public onlyOwner {
        game_alive = false;
        return;
    }

    function startGame() public onlyOwner {
        game_alive = true;
        return;
    }

    function transferHouseEdge(uint amount) public onlyOwner payable {
        require(amount <= house_edge);
        require((address(this).balance - amount) > 0);

        owner.transfer(amount);
        house_edge = house_edge - amount;
    }
}