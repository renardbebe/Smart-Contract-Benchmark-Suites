 

pragma solidity ^0.4.23;

contract XToken {
     
    struct Goods {
        string _desc;    
        string _name;    
        string _unit;    
        uint _price;     
        address _shopowner;  
    }

     
    struct ShoppingItem {
        uint _id;
        uint _count;
    }
    struct ShoppingList {
        address _buyer;
        ShoppingItem[] _items;
    }

    address private _owner;  
    address private _finance;  
    uint private _percentage;  

     
    Goods[] private _goods;
     
    ShoppingList[] private _buyers;


	mapping (address => uint) private balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);


	function send_coin(address from, address to, uint amount) private returns(bool sufficient) {
		require(balances[from] > amount, "发起交易的账号没有更多额度");

		balances[from] -= amount;
		balances[to] += amount;

		emit Transfer(from, to, amount);
		return true;
	}

     
    function recharge(address to, uint amount) public returns(bool) {
        balances[to] += amount;
        balances[_owner] -= amount; 
        emit Transfer(_owner, to, amount);
        return true;
    } 

    constructor(uint percent) public {
		 

         
        _percentage = percent; 

         
        _owner = address(0x420534893844e08af857df1b4ee8e25b09eed227);  
        _finance = address(0x1Af666fB7D3fF7096eA3b47AB2A710fF10E5Cd41);

         
         
         
        balances[_owner] = 100000000000;
    }

    function set_percentage(uint percentage) public {
        require(msg.sender == _owner, "非平台管理员，不能修改提成");

        _percentage = percentage;
    }

     
    function add_goods(string name, string unit, uint price, address shopowner, string desc) public returns(uint) {
        require(price > 0, "商品价格需要大于0");
        require(shopowner != address(0), "商家地址不能为空");
         
        Goods memory newGoods = Goods({
            _name: name,
            _unit: unit,
            _price: price,
            _shopowner: shopowner,
            _desc: desc
        });
        
        _goods.push(newGoods);

         
        return _goods.length;
    }

    function sell_goods(uint goodsID, uint count, address buyer) public returns(uint) {
         
        
        require(count > 0, "购买数据不能为0");
        require(buyer != address(0), "买家不能为空");

         

        uint price;
        uint p_shop;
        uint p_owner;
         
        for (uint i = 0; i < _goods.length; i++) {
            if( i ==  goodsID) {

                price = _goods[i]._price * count;

                p_shop = price * (100 - _percentage) / 100;
                p_owner = price * _percentage;

                if(false == send_coin(buyer, _goods[i]._shopowner, p_shop)) {
                    return 0;
                }
                if(false == send_coin(buyer, _finance, p_owner)) {
                    return 0;
                }

                 
                return price;
            }
        }

        return 0;
    }



    function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
         
        for (uint i = 0; i < a.length; i ++)
            if (a[i] != b[i])
            {
                return false;
            }    
        return true;
    }
    

	function get_balance(address addr) public returns(uint) {
		return balances[addr];
	}
}