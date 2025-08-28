using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NailApi.Migrations
{
    /// <inheritdoc />
    public partial class UpdateOrderCategoryIds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CategoryId",
                table: "Order");

            migrationBuilder.AddColumn<string>(
                name: "CategoryIds",
                table: "Order",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CategoryIds",
                table: "Order");

            migrationBuilder.AddColumn<Guid>(
                name: "CategoryId",
                table: "Order",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));
        }
    }
}
