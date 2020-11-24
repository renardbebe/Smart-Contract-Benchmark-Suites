 

pragma solidity ^0.4.11;

contract Pixel {
     
    struct Section {
        address owner;
        uint256 price;
        bool for_sale;
        bool initial_purchase_done;
        uint image_id;
        string md5;
        uint last_update;
        address sell_only_to;
        uint16 index;
         
    }
    string public standard = "IPO 0.9";
    string public constant name = "Initial Pixel Offering";
    string public constant symbol = "IPO";
    uint8 public constant decimals = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public ethBalance;
    address owner;
    uint256 public ipo_price;
    Section[10000] public sections;
    uint256 public pool;
    uint public mapWidth;
    uint public mapHeight;
    uint256 tokenTotalSupply = 10000;

    event Buy(uint section_id);
    event NewListing(uint section_id, uint price);
    event Delisted(uint section_id);
    event NewImage(uint section_id);
    event AreaPrice(uint start_section_index, uint end_section_index, uint area_price);
    event SentValue(uint value);
    event PriceUpdate(uint256 price);
    event WithdrawEvent(string msg);

    function Pixel() {
        pool = tokenTotalSupply;  
        ipo_price = 100000000000000000;  
        mapWidth = 1000;
        mapHeight = 1000;
        owner = msg.sender;
    }

    function totalSupply() constant returns (uint totalSupply)
    {
        totalSupply = tokenTotalSupply;
    }

     
     
    function updatePixelIndex(
        uint16 _start,
        uint16 _end
    ) {
        if(msg.sender != owner) throw; 
        if(_end < _start) throw;
        while(_start < _end)
        {
            sections[_start].index = _start;
            _start++;
        }
    }

     
    function updateIPOPrice(
        uint256 _new_price
    ) {
        if(msg.sender != owner) throw;
        ipo_price = _new_price;
        PriceUpdate(ipo_price);
    }

     
     
     
    function getSectionIndexFromRaw(
        uint _x,
        uint _y
    ) returns (uint) {
        if (_x >= mapWidth) throw;
        if (_y >= mapHeight) throw;
         
        _x = _x / 10;
        _y = _y / 10;
         
        return _x + (_y * 100);
    }

     
     
     
     
    function getSectionIndexFromIdentifier (
        uint _x_section_identifier,
        uint _y_section_identifier
    ) returns (uint) {
        if (_x_section_identifier >= (mapWidth / 10)) throw;
        if (_y_section_identifier >= (mapHeight / 10)) throw;
        uint index = _x_section_identifier + (_y_section_identifier * 100);
        return index;
    }

     
     
     
     
    function getIdentifierFromSectionIndex(
        uint _index
    ) returns (uint x, uint y) {
        if (_index > (mapWidth * mapHeight)) throw;
        x = _index % 100;
        y = (_index - (_index % 100)) / 100;
    }

     
     
    function sectionAvailable(
        uint _section_index
    ) returns (bool) {
        if (_section_index >= sections.length) throw;
        Section s = sections[_section_index];
         
        return !s.initial_purchase_done;
    }

     
     
    function sectionForSale(
        uint _section_index
    ) returns (bool) {
        if (_section_index >= sections.length) throw;
        Section s = sections[_section_index];
         
        if(s.for_sale)
        {
             
            if(s.sell_only_to == 0x0) return true;
            if(s.sell_only_to == msg.sender) return true;
            return false;
        }
        else
        {
             
            return false;
        }
    }

     
     
     
     
    function sectionPrice(
        uint _section_index
    ) returns (uint) {
        if (_section_index >= sections.length) throw;
        Section s = sections[_section_index];
        return s.price;
    }

     
     
     
     
     
     
    function regionAvailable(
        uint _start_section_index,
        uint _end_section_index
    ) returns (bool available, uint extended_price, uint ipo_count) {
        if (_end_section_index < _start_section_index) throw;
        var (start_x, start_y) = getIdentifierFromSectionIndex(_start_section_index);
        var (end_x, end_y) = getIdentifierFromSectionIndex(_end_section_index);
        if (start_x >= mapWidth) throw;
        if (start_y >= mapHeight) throw;
        if (end_x >= mapWidth) throw;
        if (end_y >= mapHeight) throw;
        uint y_pos = start_y;
        available = false;
        extended_price = 0;
        ipo_count = 0;
        while (y_pos <= end_y)
        {
            uint x_pos = start_x;
            while (x_pos <= end_x)
            {
                uint identifier = (x_pos + (y_pos * 100));
                 
                if(sectionAvailable(identifier))
                {
                     
                    ipo_count = ipo_count + 1;
                } else
                {
                     
                     
                    if(sectionForSale(identifier))
                    {
                        extended_price = extended_price + sectionPrice(identifier);
                    } else
                    {
                        available = false;
                         
                         
                        extended_price = 0;
                        ipo_count = 0;
                        return;
                    }
                }
                x_pos = x_pos + 1;
            }
            y_pos = y_pos + 1;
        }
        available = true;
        return;
    }

     
     
    function buySection (
        uint _section_index,
        uint _image_id,
        string _md5
    ) payable {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(!section.for_sale && section.initial_purchase_done)
        {
             
            throw;
        }
         
         
        if(section.initial_purchase_done)
        {
             
            if(msg.value < section.price)
            {
                 
                throw;
            } else
            {
                 
                 
                if (section.price != 0)
                {
                    uint fee = section.price / 100;
                     
                    ethBalance[owner] += fee;
                     
                    ethBalance[section.owner] += (msg.value - fee);
                }
                 
                 
                ethBalance[msg.sender] += (msg.value - section.price);
                 
                balanceOf[section.owner]--;
                 
                balanceOf[msg.sender]++;
            }
        } else
        {
             
            if(msg.value < ipo_price)
            {
                 
                throw;
            } else
            {
                 
                ethBalance[owner] += msg.value;
                 
                 
                ethBalance[msg.sender] += (msg.value - ipo_price);
                 
                pool--;
                 
                balanceOf[msg.sender]++;
            }
        }
         
         
        section.owner = msg.sender;
        section.md5 = _md5;
        section.image_id = _image_id;
        section.last_update = block.timestamp;
        section.for_sale = false;
        section.initial_purchase_done = true;  
    }

     
     
     
     
     
    function buyRegion(
        uint _start_section_index,
        uint _end_section_index,
        uint _image_id,
        string _md5
    ) payable returns (uint start_section_y, uint start_section_x,
    uint end_section_y, uint end_section_x){
        if (_end_section_index < _start_section_index) throw;
        if (_start_section_index >= sections.length) throw;
        if (_end_section_index >= sections.length) throw;
         
         
        var (available, ext_price, ico_amount) = regionAvailable(_start_section_index, _end_section_index);
        if (!available) throw;

         
        uint area_price =  ico_amount * ipo_price;
        area_price = area_price + ext_price;
        AreaPrice(_start_section_index, _end_section_index, area_price);
        SentValue(msg.value);
        if (area_price > msg.value) throw;

         
         
        ico_amount = 0;
         
         
        ext_price = 0;

         
        start_section_x = _start_section_index % 100;
        end_section_x = _end_section_index % 100;
        start_section_y = _start_section_index - (_start_section_index % 100);
        start_section_y = start_section_y / 100;
        end_section_y = _end_section_index - (_end_section_index % 100);
        end_section_y = end_section_y / 100;
        uint x_pos = start_section_x;
        while (x_pos <= end_section_x)
        {
            uint y_pos = start_section_y;
            while (y_pos <= end_section_y)
            {
                 
                Section s = sections[x_pos + (y_pos * 100)];
                if (s.initial_purchase_done)
                {
                     
                     
                     
                    if(s.price != 0)
                    {
                         
                        ethBalance[owner] += (s.price / 100);
                         
                        ethBalance[s.owner] += (s.price - (s.price / 100));
                    }
                     
                     
                    ext_price += s.price;
                     
                    balanceOf[s.owner]--;
                     
                    balanceOf[msg.sender]++;
                } else
                {
                     
                     
                    ethBalance[owner] += ipo_price;
                     
                     
                     
                    ico_amount += ipo_price;
                     
                    pool--;
                     
                    balanceOf[msg.sender]++;
                }

                 
                 
                s.owner = msg.sender;
                s.md5 = _md5;
                s.image_id = _image_id;
                 
                s.for_sale = false;
                s.initial_purchase_done = true;  

                Buy(x_pos + (y_pos * 100));
                 
                y_pos = y_pos + 1;
            }
            x_pos = x_pos + 1;
        }
        ethBalance[msg.sender] += msg.value - (ext_price + ico_amount);
        return;
    }

     
     
     
    function setSectionForSale(
        uint _section_index,
        uint256 _price
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.price = _price;
        section.for_sale = true;
        section.sell_only_to = 0x0;
        NewListing(_section_index, _price);
    }

     
     
     
    function setRegionForSale(
        uint _start_section_index,
        uint _end_section_index,
        uint _price
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                    section.price = _price;
                    section.for_sale = true;
                    section.sell_only_to = 0x0;
                    NewListing(x_pos + (y_pos * 100), _price);
                }
                y_pos++;
            }
            x_pos++;
        }
    }

     
     
     
     
     
     
    function setRegionForSaleToAddress(
        uint _start_section_index,
        uint _end_section_index,
        uint _price,
        address _only_sell_to
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                    section.price = _price;
                    section.for_sale = true;
                    section.sell_only_to = _only_sell_to;
                    NewListing(x_pos + (y_pos * 100), _price);
                }
                y_pos++;
            }
            x_pos++;
        }
    }

     
     
     
     
     
     
    function setRegionImageDataCloud(
        uint _start_section_index,
        uint _end_section_index,
        uint _image_id,
        string _md5
    ) {
        if (_end_section_index < _start_section_index) throw;
        var (start_x, start_y) = getIdentifierFromSectionIndex(_start_section_index);
        var (end_x, end_y) = getIdentifierFromSectionIndex(_end_section_index);
        if (start_x >= mapWidth) throw;
        if (start_y >= mapHeight) throw;
        if (end_x >= mapWidth) throw;
        if (end_y >= mapHeight) throw;
        uint y_pos = start_y;
        while (y_pos <= end_y)
        {
            uint x_pos = start_x;
            while (x_pos <= end_x)
            {
                uint identifier = (x_pos + (y_pos * 100));
                Section s = sections[identifier];
                if(s.owner == msg.sender)
                {
                    s.image_id = _image_id;
                    s.md5 = _md5;
                }
                x_pos = x_pos + 1;
            }
            y_pos = y_pos + 1;
        }
        NewImage(_start_section_index);
        return;
    }

     
     
     
    function setSectionForSaleToAddress(
        uint _section_index,
        uint256 _price,
        address _to
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.price = _price;
        section.for_sale = true;
        section.sell_only_to = _to;
        NewListing(_section_index, _price);
    }

     
     
    function unsetSectionForSale(
        uint _section_index
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.for_sale = false;
        section.price = 0;
        section.sell_only_to = 0x0;
        Delisted(_section_index);
    }

     
     
     
    function unsetRegionForSale(
        uint _start_section_index,
        uint _end_section_index
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                    section.for_sale = false;
                    section.price = 0;
                    Delisted(x_pos + (y_pos * 100));
                }
                y_pos++;
            }
            x_pos++;
        }
    }

     
    function setImageData(
        uint _section_index
         
         
         
         
         
         
         
         
         
         
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
         
         
         
         
         
         
         
         
         
         
        section.image_id = 0;
        section.md5 = "";
        section.last_update = block.timestamp;
        NewImage(_section_index);
    }

     
     
    function setImageDataCloud(
        uint _section_index,
        uint _image_id,
        string _md5
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.image_id = _image_id;
        section.md5 = _md5;
        section.last_update = block.timestamp;
        NewImage(_section_index);
    }

     
    function withdraw() returns (bool) {
        var amount = ethBalance[msg.sender];
        if (amount > 0) {
             
             
             
            ethBalance[msg.sender] = 0;
            WithdrawEvent("Reset Sender");
            msg.sender.transfer(amount);
        }
        return true;
    }

     
    function deposit() payable
    {
        ethBalance[msg.sender] += msg.value;
    }

     
    function transfer(
      address _to,
      uint _section_index
    ) {
        if (_section_index > 9999) throw;
        if (sections[_section_index].owner != msg.sender) throw;
        if (balanceOf[_to] + 1 < balanceOf[_to]) throw;
        sections[_section_index].owner = _to;
        sections[_section_index].for_sale = false;
        balanceOf[msg.sender] -= 1;
        balanceOf[_to] += 1;
    }



     
    function transferRegion(
        uint _start_section_index,
        uint _end_section_index,
        address _to
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                  if (balanceOf[_to] + 1 < balanceOf[_to]) throw;
                  section.owner = _to;
                  section.for_sale = false;
                  balanceOf[msg.sender] -= 1;
                  balanceOf[_to] += 1;
                }
                y_pos++;
            }
            x_pos++;
        }
    }
}