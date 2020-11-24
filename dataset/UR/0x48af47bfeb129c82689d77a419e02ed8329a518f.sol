 

pragma solidity ^ 0.4.23;
 
contract EtherealTarot {

    struct reading {  
        uint8[] cards;
        bool[] upright;
        uint8 count;
    }

  mapping(address => reading) readings;

  uint8[78] cards;
  uint8 deckSize = 78;
  address public creator;

  constructor() public {
    creator = msg.sender;
    for (uint8 card = 0; card < deckSize; card++) {
      cards[card] = card;
    }
  }
    
  function draw(uint8 index, uint8 count) private {
     
     
     
    uint8 drawnCard = cards[index];
    uint8 tableIndex = deckSize - count - 1;
    cards[index] = cards[tableIndex];
    cards[tableIndex] = drawnCard;
  }

  function draw_random_card(uint8 count) private returns(uint8) {
    uint8 random_card = random(deckSize - count, count);
    draw(random_card, count);
    return random_card;
  }

  function random(uint8 range, uint8 count) view private returns(uint8) {
    uint8 _seed = uint8(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              blockhash(block.number),
              _seed)
          ), now + count)
      )
    );
    return _seed % (range);
  }
  function random_bool(uint8 count) view private returns(bool){
      return 0==random(2,count);
  }

  function spread(uint8 requested) private {
     
    uint8[] memory table = new uint8[](requested);
     
    bool[] memory upright = new bool[](requested);

     
    for (uint8 position = 0; position < requested; position++) {
      table[position] = draw_random_card(position);
      upright[position] = random_bool(position);
    }
    readings[msg.sender]=reading(table,upright,requested);
  }


  function has_reading() view public returns(bool) {
    return readings[msg.sender].count!=0;
  }
  function reading_card_at(uint8 index) view public returns(uint8) {
    return readings[msg.sender].cards[index];
  }
  function reading_card_upright_at(uint8 index) view public returns(bool) {
    return readings[msg.sender].upright[index];
  }

   
  function withdraw() public {
    require(msg.sender == creator);
    creator.transfer(address(this).balance);
  }
    
   
  function career_path() payable public {
    spread(7);
  }

  function celtic_cross() payable public {
    spread(10);
  }

  function past_present_future() payable public {
    spread(3);
  }

  function success() payable public {
    spread(5);
  }

  function spiritual_guidance() payable public {
    spread(8);
  }

  function single_card() payable public {
    spread(1);
  }
  function situation_challenge() payable public {
    spread(2);
  }

  function seventeen() payable public {
    spread(17);
  }
  
}