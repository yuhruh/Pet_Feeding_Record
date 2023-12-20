require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "amount")
    @logger = logger
    @headers = %w[Date Time Category Amount Modify Delete]
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def get_headers
    @headers
  end

  def get_table_row
    sql = "SELECT * FROM amount_food ORDER BY date, time, id"
    result = query(sql)

    result.map do |tuple|
      {id: tuple["id"], date: tuple["date"], time: tuple["time"], category: tuple["category"], amount: tuple["amount"]}
    end
  end

  def create_new_row(category, amount)
    sql = "INSERT INTO amount_food (category, amount) VALUES ($1, $2)"
    query(sql, category, amount)
  end

  def delete_table_row(id)
    sql = "DELETE FROM amount_food WHERE id = $1"
    query(sql, id)
  end

  def update_table_row(id, new_category, new_amount)
    sql = "UPDATE amount_food SET category = $1, amount = $2 WHERE id = $3"
    query(sql, new_category, new_amount, id)
  end
end