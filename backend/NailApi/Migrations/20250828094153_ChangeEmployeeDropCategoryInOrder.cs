using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NailApi.Migrations
{
    /// <inheritdoc />
    public partial class ChangeEmployeeDropCategoryInOrder : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CategoryIds",
                table: "Order");

            migrationBuilder.DropColumn(
                name: "EmployeeId",
                table: "Order");

            migrationBuilder.RenameColumn(
                name: "EmployeeName",
                table: "Order",
                newName: "EmployeeNames");

            migrationBuilder.RenameColumn(
                name: "CategoryName",
                table: "Order",
                newName: "EmployeeIds");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "EmployeeNames",
                table: "Order",
                newName: "EmployeeName");

            migrationBuilder.RenameColumn(
                name: "EmployeeIds",
                table: "Order",
                newName: "CategoryName");

            migrationBuilder.AddColumn<string>(
                name: "CategoryIds",
                table: "Order",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "EmployeeId",
                table: "Order",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));
        }
    }
}
