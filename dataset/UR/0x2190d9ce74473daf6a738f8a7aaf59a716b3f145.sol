 

pragma solidity >=0.4.21 <0.7.0;


contract Random {
    address public owner;

    uint32[] public _tickets;
    uint32[] public _winners;
    uint32[] public _winners_tickets;

    constructor() public {
        owner = msg.sender;
    }

    bytes32 public current_block_hash;
    uint256 public current_block_id;


    function clear() public returns (bool){
        require(msg.sender==owner, "Not the owner");
        delete _tickets;
        delete _winners;
        delete _winners_tickets;
    }

    function bulk_load_tickets(uint32[] memory tickets) public returns (bool){
        require(msg.sender==owner, "Not the owner");
        for(uint256 i = 0 ; i < tickets.length ; i++  ){
            _tickets.push(tickets[i]);
        }
    }

    function is_winner(uint32 winner_idx) public view returns(bool){
        for(uint256 i = 0 ; i < _winners.length; i ++){
            if( _winners[i] == winner_idx ){
                return true;
            }
        }
        return false;
    }

    function random_winners(uint32 winnersCount) public returns (bool){
        require(msg.sender==owner, "Not the owner");
         current_block_id = block.number;
         current_block_hash = blockhash(current_block_id - 1);
         uint256 random_number = uint256(sha256(abi.encodePacked(current_block_hash)));
         delete _winners;
         delete _winners_tickets;

         for(uint32 i = 0 ; i < winnersCount; i ++){
             uint32 winner_idx = uint32(random_number % _tickets.length);
             do {
                 random_number = uint256(sha256(abi.encodePacked(random_number)));
                 winner_idx = uint32(random_number % _tickets.length);
             } while( is_winner(winner_idx) );
             _winners.push(winner_idx);
             _winners_tickets.push(_tickets[winner_idx]);
         }
    }

    function get_all_tickets() public view returns (uint32[] memory){
        return _tickets;
    }

    function get_all_winners() public view returns (uint32[] memory){
        return _winners;
    }

    function get_all_winners_tickets() public view returns (uint32[] memory){
        return _winners_tickets;
    }

}