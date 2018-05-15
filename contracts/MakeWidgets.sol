pragma solidity ^0.4.23; 

import "./SupplyChain.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MakeWidgets is Ownable, SupplyChain {

    mapping(address => bool) trustedWidgets; 
    address[] public orderList; 

    function widgetOrder() public onlyOwner returns(address) {

        SupplyChain newWidgetOrder = new SupplyChain(); 
        trustedWidgets[newWidgetOrder] = true;
        orderList.push(newWidgetOrder);
        newWidgetOrder.transferOwnership(msg.sender);
        return newWidgetOrder; 

    }
}